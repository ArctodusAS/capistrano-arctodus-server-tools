namespace :monit do
  desc "Stop Monit"
  task :stop do
    on roles(:app) do
      execute "sudo /bin/systemctl stop #{fetch :monit_service_name}"
    end
  end

  desc "Start Monit"
  task :start do
    on roles(:app) do
      execute "sudo /bin/systemctl start #{fetch :monit_service_name}"
    end
  end

  desc "Stops Monit if there are pending migrations"
  task :migration_dependent_stop do
    on roles(:app) do
      if migration_change?
        info "Migration change detected"
      else
        info "No migration change detected"
      end

      if monit_running?
        info "Monit is running"
      else
        info "Monit is not running or not enabled"
      end

      if migration_change? && monit_running?
        info "Stopping Monit temporarily."
        set :_monit_temporarily_stopped, true
        invoke "monit:stop"
      else
        info "No migration change detected"
      end
    end
  end

  desc "Restarts Monit if it was temporarily stopped"
  task :migration_dependent_start do
    on roles(:app) do
      if fetch(:_monit_temporarily_stopped)
        info "Monit was temporarily stopped. Restarting."
        invoke "monit:start"
      end
    end
  end
end
