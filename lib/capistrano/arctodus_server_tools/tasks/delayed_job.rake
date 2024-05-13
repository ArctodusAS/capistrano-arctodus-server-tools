namespace :delayed_job do
  desc 'Stop the delayed_job process'
  task :stop do
    on roles(:app) do
      info "Restarting delayed_job. Will wait a bit for running jobs to finish before killing them."
      execute "sudo /bin/systemctl stop #{fetch :delayed_job_service_name}"
    end
  end

  desc 'Start the delayed_job process'
  task :start do
    on roles(:app) do
      execute "sudo /bin/systemctl start #{fetch :delayed_job_service_name}"
    end
  end

  desc 'Restart the delayed_job process'
  task :restart do
    on roles(:app) do
      invoke "delayed_job:stop"
      invoke "delayed_job:start"
    end
  end
end
