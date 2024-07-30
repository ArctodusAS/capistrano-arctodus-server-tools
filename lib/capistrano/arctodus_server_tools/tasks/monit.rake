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

  desc "Stops Monit temporarily if it is running"
  task :stop_before_migration do
    on roles(:app) do
      if monit_running?
        info "Stopping Monit temporarily."
        set :_monit_temporarily_stopped, true
        invoke "monit:stop"
      else
        info "Monit is running"
      end
    end
  end

  desc "Restarts Monit if it was temporarily stopped"
  task :restart_after_migration do
    on roles(:app) do
      if fetch(:_monit_temporarily_stopped)
        info "Monit was temporarily stopped. Restarting."
        invoke "monit:start"
      end
    end
  end
end
