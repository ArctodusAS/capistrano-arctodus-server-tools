# Arctodus server tools

Zero downtime deploys with Puma, Rbenv, SystemD and Capistrano.  
DB sync server->local with pg_dump/pg_restore.

Gemfile:
```ruby
gem 'capistrano-arctodus-server-tools', git: "git@github.com:ArctodusAS/capistrano-arctodus-server-tools.git", require: false
```

Capfile:
```ruby
require 'capistrano/arctodus_server_tools'
install_plugin Capistrano::ArctodusServerTools::Plugin
```

**Development / contributing**

Temporarily set a local path in the Gemfile
```ruby
gem 'capistrano-arctodus-server-tools', path: '/code/gems/capistrano-arctodus-server-tools', require: false
```
Make changes on new branch and open Github PR
