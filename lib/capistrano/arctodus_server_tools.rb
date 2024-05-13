module Capistrano::ArctodusServerTools
end

require 'capistrano/arctodus_server_tools/dsl'
require 'capistrano/arctodus_server_tools/plugin'

Capistrano::DSL.include(Capistrano::ArctodusServerTools::DSL)
