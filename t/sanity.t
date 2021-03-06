# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_KT_PORT} = 1978;

no_long_string();

log_level('notice');

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            local ok, err = ktc:set("kyoto", "tycoon")
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ngx.say("set kyoto ok")

            local res, err = ktc:get("kyoto")
            if err then
                ngx.say("failed to get kyoto: ", err)
                return
            end

            if not res then
                ngx.say("kyoto not found.")
                return
            else
                ngx.say("kyoto: ", res)
            end

            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set kyoto ok
kyoto: tycoon



=== TEST 2: set number
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            ok, err = ktc:set("count", 1)
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ngx.say("set count ok")

            local res, err = ktc:get("count")
            if err then
                ngx.say("failed to get count ", err)
                return
            end

            if not res then
                ngx.say("count not found.")
                return
            else
                ngx.say("count: ", res)
            end

            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set count ok
count: 1



=== TEST 3: get_bulk
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            ok, err = ktc:set("kyoto", "tycoon")
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ok, err = ktc:set("tokyo", "cabinet")
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ngx.say("set kyoto, tokyo ok")

            local res, err = ktc:get_bulk{ "kyoto", "tokyo" }
            if err then
                ngx.say("failed to get kyoto: ", err)
                return
            end

            for _, v in ipairs(res) do
                ngx.say(v.key, ": ", v.value)
            end
            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set kyoto, tokyo ok
kyoto: tycoon
tokyo: cabinet



=== TEST 4: sanity
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            ok, err = ktc:set("kyoto", "tycoon")
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ngx.say("set kyoto ok")

            local res, err = ktc:get_bulk({"kyoto", "tokyo" })
            if err then
                ngx.say("failed to get kyoto: ", err)
                return
            end

            for _, v in ipairs(res) do
                ngx.say(v.key, ": ", v.value)
            end
            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set kyoto ok
kyoto: tycoon



=== TEST 5: set_bulk
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            ok, err = ktc:set_bulk{
                {"kyoto", "tycoon"},
                {"tokyo", "cabinet"}
            }
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            ngx.say("set kyoto, tokyo ok")

            local res, err = ktc:get_bulk{ "kyoto", "tokyo" }
            if err then
                ngx.say("failed to get kyoto: ", err)
                return
            end

            for _, v in ipairs(res) do
                ngx.say(v.key, ": ", v.value)
            end
            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set kyoto, tokyo ok
kyoto: tycoon
tokyo: cabinet



=== TEST 6: remove_bulk
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local kt = require "resty.kyototycoon"
            local ktc = kt:new()

            ktc:set_timeout(1000) -- 1 sec

            local ok, err = ktc:connect("127.0.0.1", $TEST_NGINX_KT_PORT)
            if not ok then
                ngx.say("failed to connect to kt: ", err)
                return
            end

            ok, err = ktc:set_bulk{
                {"kyoto", "tycoon"},
                {"tokyo", "cabinet"},
                {"osaka", "tyrant"}
            }
            if not ok then
                ngx.say("failed to set_bulk: ", err)
                return
            end

            ngx.say("set kyoto, tokyo ok")

            local res, err = ktc:remove_bulk({ "kyoto", "tokyo" })
            if err then
                ngx.say("failed to remove_bulk: ", err)
                return
            end

            res, err = ktc:get_bulk({ "kyoto", "tokyo", "osaka" })
            if err then
                ngx.say("failed to get_bulk: ", err)
                return
            end

            for _, v in ipairs(res) do
                ngx.say(v.key, ": ", v.value)
            end
            ktc:close()
        ';
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
set kyoto, tokyo ok
osaka: tyrant

