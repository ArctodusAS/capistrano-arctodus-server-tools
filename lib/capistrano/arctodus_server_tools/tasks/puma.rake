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
  # For some reason Puma wont start without the correct version of Bundler in the system gems
  task :check_ruby_bundler do
    on roles(:app) do
      within release_path do
        path_prefix = "PATH=#{fetch(:rbenv_path)}/shims:#{fetch(:rbenv_path)}/bin:$PATH"
        bundled_with = capture :tail, "-n1", 'Gemfile.lock'
        bundler_installed = test("cd #{release_path} && #{path_prefix} gem list -i bundler -v #{bundled_with}")
        info "Bundler v#{bundled_with} installed: #{bundler_installed}"
        unless bundler_installed
          execute "cd #{release_path}  && #{path_prefix} gem install bundler -v #{bundled_with}"
        end
        # Maybe there is a cleaner way by to do this by temporarily changing the capistrano-bundler
        # configuration to make it check system gems instead of the deployment gems in shared_path/bundle.
      end
    end
  end
end
