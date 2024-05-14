class Capistrano::ArctodusServerTools::Plugin < Capistrano::Plugin
  def set_defaults
    set_if_empty :puma_service_name, -> { "puma_#{fetch :application}" }
    set_if_empty :delayed_job_service_name, -> { "delayed_job_#{fetch :application}" }
    set_if_empty :puma_pid_path, -> { shared_path.join("tmp", "pids", fetch(:puma_service_name) + ".pid") }
    set_if_empty :repo_url, -> { "git@github.com:ArctodusAS/#{fetch :application}.git" }
    set_if_empty :rbenv_type, :system
  end

  def register_hooks
    before "bundler:install", "puma:check_ruby_bundler"
  end

  def define_tasks
    %w(puma delayed_job).each do |task|
      eval_rakefile File.expand_path("../tasks/#{task}.rake", __FILE__)
    end
  end
end
