desc "Copy DB from server to local machine"
task :fetch_server_db do
  require 'tty-spinner'
  on roles(:app) do
    color = SSHKit::Color.new($stdout)

    warn "#{color.colorize(fetch(:remote_db), :blue)} will be copied from #{color.colorize(fetch(:stage), :red)} and written to #{color.colorize(fetch(:local_db), :blue)} locally. Keep #{color.colorize('GDPR', :red)} in mind."
    info 'Press y to continue.'
    confirm = STDIN.gets.strip
    unless confirm == 'y'
      warn 'Task aborted'
      exit
    end

    local_dump_path = fetch(:local_db_dump_path)
    remote_dump_path = "/tmp/db_export_#{fetch :remote_db}_#{Time.now.to_i}.sql"
    raise "Local file already exists: #{local_dump_path}" if File.exist?(local_dump_path)
    raise "/tmp/db_export* already exists on the server" if test('ls /tmp/ | grep db_export')

    spinner = TTY::Spinner.new("      Exporting database with pg_dump :spinner       ", format: :dots_2, interval: 5)
    spinner.auto_spin
    execute "pg_dump -F c -Z 1 -c #{fetch :remote_db} > #{remote_dump_path}"
    spinner.stop
    download! remote_dump_path, local_dump_path
    execute "rm #{remote_dump_path}"

    invoke "pg_restore_locally"
    %x{ rm #{local_dump_path} } unless ENV['KEEP_DUMP']

    info 'Database successfully imported'
  end
end

desc "Drop and recreate local database based on the dump file"
task :pg_restore_locally do
  require 'tty-spinner'
  run_locally do
    local_dump_path = fetch(:local_db_dump_path)
    raise "Local file missing: #{local_dump_path}" unless File.exist?(local_dump_path)
    system("RAILS_ENV=development bundle exec rake db:drop", exception: true)
    system("RAILS_ENV=development bundle exec rake db:create", exception: true)
    system("pg_restore --verbose --no-acl --no-owner -j 4 -d #{fetch :local_db} #{local_dump_path}", exception: true)
    system("RAILS_ENV=development bundle exec rake db:migrate", exception: true) unless ENV['MIGRATE'] == 'false'
    system("RAILS_ENV=development bundle exec rake db:environment:set", exception: true)
    system("RAILS_ENV=development bundle exec rake parallel:load_schema", exception: true) if defined?(ParallelTests)
  end
end
