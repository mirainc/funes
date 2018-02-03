#!/usr/bin/perl

# Copyright (C) 2010-2013 Alibaba Group Holding Limited

# Tests for connect method support.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

my $t = Test::Nginx->new()->has(qw/http proxy/)->plan(10);

$t->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    log_format connect '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent var:$connect_host-$connect_port-$connect_addr';

    access_log %%TESTDIR%%/connect.log connect;

    resolver 8.8.8.8;

    server {
        listen  8081;
        listen  8082;
        listen  8083;
        server_name server_8081;
        access_log off;
        location / {
            return 200 "hello $remote_addr $server_port\n";
        }
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        set $proxy_remote_address "";
        set $proxy_local_address "";
        # forward proxy for CONNECT method
        proxy_connect;
        proxy_connect_allow 443 80 8081;
        proxy_connect_connect_timeout 10s;
        proxy_connect_read_timeout 10s;
        proxy_connect_send_timeout 10s;
        proxy_connect_send_lowat 0;
        proxy_connect_address $proxy_remote_address;
        proxy_connect_bind $proxy_local_address;

        if ($host = "address.com") {
            set $proxy_remote_address "127.0.0.1:8082";
        }

        if ($host = "bind.com") {
            set $proxy_remote_address "127.0.0.1:8083";
            set $proxy_local_address "127.0.0.3";
        }

        location / {
            proxy_pass http://127.0.0.1:8081;
        }

        location = /hello {
            return 200 "world";
        }

        # used to output connect.log
        location = /connect.log {
            access_log off;
            root %%TESTDIR%%/;
        }
    }
}

EOF

###############################################################################

$t->run();

like(http_connect_request('127.0.0.1', '8081', '/'), qr/hello/, '200 Connection Established');
like(http_connect_request('www.baidu.com', '80', '/'), qr/baidu/, '200 Connection Established server name');
like(http_connect_request('www.taobao.com', '80', '/'), qr/taobao/, '200 Connection Established server name');
like(http_connect_request('www.taobao111114.com', '80', '/'), qr/502/, '200 Connection Established server name');
like(http_connect_request('127.0.0.1', '9999', '/'), qr/403/, '200 Connection Established not allowed port');
like(http_get('/'), qr/hello/, 'Get method: proxy_pass');
like(http_get('/hello'), qr/world/, 'Get method: return 200');
like(http_connect_request('address.com', '8081', '/'), qr/hello 127.0.0.1 8082/, 'set remote address');
like(http_connect_request('bind.com', '8081', '/'), qr/hello 127.0.0.3 8083/, 'set local address and remote address');


# test $connect_host, $connect_port
my $log = http_get('/connect.log');
like($log, qr/CONNECT 127\.0\.0\.1:8081.*var:127\.0\.0\.1-8081-127\.0\.0\.1:8081/, '$connect_host, $connect_port, $connect_addr');
like($log, qr/CONNECT www\.taobao111114\.com:80.*var:www\.taobao111114\.com-80--/, 'empty variable $connect_addr');

$t->stop();

###############################################################################

$t->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    log_format connect '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent var:$connect_host-$connect_port-$connect_addr';

    access_log %%TESTDIR%%/connect.log connect;

    server {
        listen  8081;
        listen  8082;
        access_log off;
        location / {
            return 200 "hello $remote_addr $server_port\n";
        }
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        # forward proxy for CONNECT method

        proxy_connect;
        proxy_connect_allow all;

        proxy_connect_connect_timeout 10s;
        proxy_connect_read_timeout 10s;
        proxy_connect_send_timeout 10s;
        proxy_connect_send_lowat 0;

        proxy_connect_address 127.0.0.1:8082;
#        proxy_connect_bind 127.0.0.3;

        location / {
            proxy_pass http://127.0.0.1:8081;
        }
    }
}

EOF


$t->run();
like(http_connect_request('address.com', '8081', '/'), qr/hello 127.0.0.1 8082/, 'set remote address without nginx variable');
$t->stop();

###############################################################################


sub http_connect_request {
    my ($host, $port, $url) = @_;
    my $r = http_connect($host, $port, <<EOF);
GET $url HTTP/1.0
Host: $host
Connection: close

EOF
    return $r
}

sub http_connect($;%) {
    my ($host, $port, $request, %extra) = @_;
    my $reply;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        local $SIG{PIPE} = sub { die "sigpipe\n" };
        alarm(2);
        my $s = IO::Socket::INET->new(
            Proto => 'tcp',
            PeerAddr => '127.0.0.1:8080'
        );
        $s->print(<<EOF);
CONNECT $host:$port HTTP/1.1
Host: $host

EOF
        select undef, undef, undef, $extra{sleep} if $extra{sleep};
        return '' if $extra{aborted};
        my $n = $s->sysread($reply, 65536);
        return unless $n;
        if ($reply !~ /HTTP\/1\.0 200 Connection Established\r\nProxy-agent: .+\r\n\r\n/) {
            return $reply;
        }
        log_out($request);
        $s->print($request);
        local $/;
        select undef, undef, undef, $extra{sleep} if $extra{sleep};
        return '' if $extra{aborted};
        $reply = $s->getline();
        alarm(0);
    };
    alarm(0);
    if ($@) {
        log_in("died: $@");
        return undef;
    }
    log_in($reply);
    return $reply;
}
###############################################################################
