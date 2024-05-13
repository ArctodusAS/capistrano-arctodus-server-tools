Zero downtime deploys with Puma, Rbenv, SystemD and Capistrano

Add this to the Capfile:
```ruby
require 'capistrano/arctodus_server_tools'
install_plugin Capistrano::ArctodusServerTools::Plugin
```
