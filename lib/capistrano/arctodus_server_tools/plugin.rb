class Capistrano::ArctodusServerTools::Plugin < Capistrano::Plugin
  def set_defaults
    set_if_empty :puma_service_name, -> { "puma_#{fetch :application}" }
    set_if_empty :puma_pid_path, -> { shared_path.join("tmp", "pids", fetch(:puma_service_name) + ".pid") }
    set_if_empty :puma_active_timeout, 60
    set_if_empty :delayed_job_service_name, -> { "delayed_job_#{fetch :application}" }
    set_if_empty :repo_url, -> { "git@github.com:ArctodusAS/#{fetch :application}.git" }
    set_if_empty :rbenv_type, :system
    set_if_empty :remote_db, -> { "#{fetch :application}_production" }
    set_if_empty :local_db, -> { "#{fetch :application}_development" }
    set_if_empty :local_db_dump_path, -> { Pathname.new(Dir.pwd).join('tmp', 'db_export.sql').to_s }
    set_if_empty :local_db_dump_path, -> { Pathname.new(Dir.pwd).join('tmp', 'db_export.sql').to_s }
    set :conditionally_migrate, true # used by capistrano-rails
    set_if_empty :monit_service_name, "monit"
    set :_monit_temporarily_stopped, false
  end

  def register_hooks
    before "bundler:install", "puma:check_ruby_bundler"
    if Rake::Task.task_defined?('deploy:migrating')
      before "deploy:migrating", "monit:stop_before_migration"
      before "deploy:log_revision", "monit:restart_after_migration"
    end
  end

  def define_tasks
    %w(puma delayed_job monit fetch_server_db).each do |task|
      eval_rakefile File.expand_path("../tasks/#{task}.rake", __FILE__)
    end
  end
end
