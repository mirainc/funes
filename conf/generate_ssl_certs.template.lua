-- Inspired by:
-- https://blog.dutchcoders.io/openresty-with-dynamic-generated-certificates/

local ssl = require "ngx.ssl"
local resty_lock = require "resty.lock"
local lrucache = require "resty.lrucache"

-- initialize memory caches for certs/keys.
-- these lrucaches are NOT shared among nginx workers (https://github.com/openresty/lua-resty-lrucache).
-- total cert + key size is ~3KB, and we store both in the cache.
-- each nginx worker will use ~1MB for its memory cache.
local cert_mem_cache, err = lrucache.new(600)
if not cert_mem_cache then
    error("failed to create the cache: " .. (err or "unknown"))
end

function unlock_or_exit(lock)
    local ok, err = lock:unlock()
    if not ok then
        ngx.log(ngx.ERR, "failed to unlock: ", err)
        return ngx.exit(ngx.ERROR)
    end
end

function root_ca_disk_locations()
    return "${ROOT_CA_CERT}", "${ROOT_CA_KEY}"
end

function cert_disk_locations(common_name)
    local disk_cache_dir = "/data/funes/cert_cache";
    local private_key = string.format("%s/%s.key", disk_cache_dir, common_name)
    local csr = string.format("%s/%s.csr", disk_cache_dir, common_name)
    local signed_cert = string.format("%s/%s.crt", disk_cache_dir, common_name)
    return private_key, csr, signed_cert
end

function cert_info()
    return "US", "California", "San Francisco", "Raydiant"
end

function get_file_with_mem_cache(filename)
    -- try fetching from cache first.
    local data = cert_mem_cache:get(filename)
    if data then
        return data
    end

    -- if not present in cache, read from disk.
    local f = io.open(filename, "r")
    if f then
        data = f:read("*a")
        f:close()

        -- set data in cache 
        cert_mem_cache:set(filename, data, ${CERT_CACHE_TTL_SEC})
    else
        ngx.log(ngx.WARN, "Failed to read data from disk: ", filename)
    end

    return data
end

function get_signed_cert(common_name)
    local private_key, csr, signed_cert = cert_disk_locations(common_name)

    local key_data = get_file_with_mem_cache(private_key);
    local cert_data = get_file_with_mem_cache(signed_cert);

    -- return key_data, cert_data
    if key_data and cert_data then
        local key_data_der, err = ssl.priv_key_pem_to_der(key_data)
        if not key_data_der then
            ngx.log(ngx.ERR, "failed to convert private key ",
                    "from PEM to DER: ", err)
            return ngx.exit(ngx.ERROR)
        end

        local cert_data_der, err = ssl.cert_pem_to_der(cert_data)
        if not cert_data_der then
            ngx.log(ngx.ERR, "failed to convert certificate chain ",
                    "from PEM to DER: ", err)
            return ngx.exit(ngx.ERROR)
        end

        return key_data_der, cert_data_der
    end

    return nil, nil
end

-- Generate a certificate signing request.
function generate_csr(common_name)
    local private_key, csr, signed_cert = cert_disk_locations(common_name)
    local country, state, city, company = cert_info()
    local openssl_command = string.format("/bin/bash -c 'RANDFILE=/data/funes/.rnd openssl req -new -newkey rsa:2048 -keyout %s -nodes -out %s -subj \"/C=%s/ST=%s/L=%s/O=%s/CN=%s\"'", private_key, csr, country, state, city, company, common_name)
    ngx.log(ngx.ERR, openssl_command)
    local ret = os.execute(openssl_command)
    return ret
end

-- Sign a CSR using the root CA cert and key.
function sign_csr(common_name, root_ca_cert, root_ca_key)
    local private_key, csr, signed_cert = cert_disk_locations(common_name)
    local openssl_command = string.format("faketime yesterday /bin/bash -c 'RANDFILE=/data/funes/.rnd openssl x509 -req -extfile <(printf \"subjectAltName=DNS:%s\") -days 365 -in %s -CA %s -CAkey %s -CAcreateserial -out %s'", common_name, csr, root_ca_cert, root_ca_key, signed_cert)
    ngx.log(ngx.ERR, openssl_command)
    local ret = os.execute(openssl_command)
    return ret
end

-- Generate a self-signed cert end-to-end (create CSR, sign with root CA cert).
function generate_self_signed_cert(common_name)
    local ret = generate_csr(common_name)
    if not ret == 0 then
        ngx.log(ngx.ERR, "generate_csr failed with code: ", ret)
        return false
    end

    local root_ca_cert, root_ca_key = root_ca_disk_locations()
    local ret = sign_csr(common_name, root_ca_cert, root_ca_key)
    if not ret == 0 then
        ngx.log(ngx.ERR, "sign_csr failed with code: ", ret)
        return false
    end
    return true
end

-- Try to set the cert for a common name on the current response.
-- Returns false if the cert doesn't exist.
function set_cert(common_name)
    local key_data, cert_data = get_signed_cert(common_name)
    if key_data and cert_data then
        local ok, err = ssl.set_der_priv_key(key_data)
        if not ok then
            ngx.log(ngx.ERR, "failed to set DER priv key: ", err)
            return ngx.exit(ngx.ERROR)
        end
        local ok, err = ssl.set_der_cert(cert_data)
        if not ok then
            ngx.log(ngx.ERR, "failed to set DER cert: ", err)
            return ngx.exit(ngx.ERROR)
        end
        return true
    end
    return false
end

ssl.clear_certs()

local common_name = ssl.server_name()
if common_name == nil then
    common_name = "unknown"
end

-- try to set the self-signed certificate on the response.
-- this will succeed if a cert has already been generated.
local ok = set_cert(common_name)
if ok then
    return
end

-- otherwise, we need to create a new certificate.

-- prevent creating same certificate twice using lock.
local lock = resty_lock:new("my_locks")
local elapsed, err = lock:lock(common_name)
if not elapsed then
    ngx.log(ngx.ERR, "failed to acquire the lock: ", err)
    return ngx.exit(ngx.ERROR)
end

-- try to set the cert again, in case it was created by another thread.
local ok = set_cert(common_name)
if ok then
    -- unlock to avoid deadlock
    unlock_or_exit(lock)
    return
end

-- generate new private key
ngx.log(ngx.INFO, "generating key")

-- call openssl to create a new self-signed certificate in the disk cache.
local ok = generate_self_signed_cert(common_name)

-- unlock immediately after generating the cert.
unlock_or_exit(lock)

-- check whether openssl call succeeded.
if not ok then
    ngx.log(ngx.ERR, string.format("failed to generate certificate"))
    return ngx.exit(ngx.ERROR)
end

-- read the newly generated cert from disk and return.
local ok = set_cert(common_name)
if ok then
    return
end

ngx.log(ngx.ERR, "failed to read generated certificate")
return ngx.exit(ngx.ERROR)
