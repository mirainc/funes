# get it from https://github.com/nginx/nginx-tests
nginx_tests_lib_path=/path/to/nginx-tests/lib

# compiled nginx binary
nginx_binary=/path/to/nginx_binary

# path of test cases
proxy_connect_test_cases=/path/to/ngx_http_proxy_connect_module/t

TEST_NGINX_UNSAFE=yes \
TEST_NGINX_BINARY=$nginx_binary \
prove -v -I $nginx_tests_lib_path  $proxy_connect_test_cases
