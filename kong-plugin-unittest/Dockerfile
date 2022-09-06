FROM vpanov/lua-busted
USER root
ENV LUA_PATH /usr/local/custom/?.lua;;
COPY ./kong-plugin /usr/local/custom/
COPY ./kong-plugin-unittest ./kong-plugin-unittest
RUN busted --verbose ./kong-plugin-unittest/unittest_spec.lua