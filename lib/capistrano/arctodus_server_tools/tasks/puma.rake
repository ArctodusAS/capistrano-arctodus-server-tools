namespace :puma do
  desc "Puma phased restart"
  task :phased_restart do
    on roles(:app) do
      # Sends a USR2 process signal to the Puma master process
      execute "sudo /bin/systemctl reload #{fetch :puma_service_name}"
    end
  end
  desc "Puma hot restart"
  task :hot_restart do
    on roles(:app) do
      raise "Do a systemd restart intead"
      # execute "kill -s USR2 $(cat #{fetch :puma_pid_path})"
    end
  end
  desc "Puma SystemD start"
  task :systemd_start do
    on roles(:app) do
      execute "sudo /bin/systemctl start #{fetch :puma_service_name}"
    end
  end
  desc "Puma SystemD stop"
  task :systemd_stop do
    on roles(:app) do
      execute "sudo /bin/systemctl stop #{fetch :puma_service_name}"
    end
  end
  desc "Puma SystemD restart"
  task :systemd_restart do
    on roles(:app) do
      invoke "puma:systemd_stop"
      invoke "puma:systemd_start"
    end
  end
  desc "Puma SystemD release dependent restart"
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
      elsif updated_default_gems.any? # Puma phased restart will not work if a default gem exists in Gemfile.lock and it is updated
        info "default gem update detected (#{updated_default_gems.join(',')}). Doing a SystemD restart. 1 second downtime expected."
        invoke "puma:systemd_restart"
      else
        info "No Ruby, Puma or default gem update detected. Doing a zero downtime phased restart."
        invoke "puma:phased_restart"
      end
      verify_puma_service_active
    end
  end
  # For some reason Puma wont start without the correct version of Bundler in the system gems
  desc "Check server Ruby Bundler version and install if needed"
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
