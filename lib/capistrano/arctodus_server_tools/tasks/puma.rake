namespace :puma do
  task :phased_restart do
    on roles(:app) do
      execute "kill -s USR1 $(cat #{fetch :puma_pid_path})"
    end
  end
  task :hot_restart do
    on roles(:app) do
      execute "kill -s USR2 $(cat #{fetch :puma_pid_path})"
    end
  end
  task :systemd_start do
    on roles(:app) do
      execute "sudo /bin/systemctl start #{fetch :puma_service_name}"
    end
  end
  task :systemd_stop do
    on roles(:app) do
      execute "sudo /bin/systemctl stop #{fetch :puma_service_name}"
    end
  end
  task :systemd_restart do
    on roles(:app) do
      invoke "puma:systemd_stop"
      invoke "puma:systemd_start"
    end
  end
  task :release_dependent_restart do
    on roles(:app) do
      if !puma_running?
        info "Puma status: #{puma_status}"
        info "Puma is not running. Issuing a SystemD restart command."
        invoke "puma:systemd_restart"
      elsif ruby_updated?
        info "Prev Ruby: #{prev_ruby}"
        info "Current Ruby: #{current_ruby}"
        info "Ruby update detected. Doing a SystemD restart. 1 second downtime expected."
        invoke "puma:systemd_restart"
      elsif puma_updated?
        info "Prev Puma: #{prev_puma}"
        info "Current Puma: #{current_puma}"
        info "Puma update detected. Doing a SystemD restart. 1 second downtime expected."
        invoke "puma:systemd_restart"
      else
        info "No Ruby or Puma update detected. Doing a zero downtime phased restart."
        invoke "puma:phased_restart"
      end
      verify_puma_service_active
    end
  end
end
