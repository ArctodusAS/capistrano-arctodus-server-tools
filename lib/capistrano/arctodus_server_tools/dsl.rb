module Capistrano::ArctodusServerTools::DSL
  def monit_status
    capture("systemctl show -p ActiveState --value #{fetch :monit_service_name}")
  end

  def monit_running?
    monit_status == 'active'
  end

  def migration_change?
    !test(:diff, "-qr #{release_path}/db #{current_path}/db")
  end

  def ruby_updated?
    current_ruby != prev_ruby
  end

  def puma_updated?
    current_puma != prev_puma
  end

  def puma_running?
    puma_status == 'active'
  end

  def prev_ruby
    capture(:cat, prev_release_path.join(".ruby-version"))
  end

  def current_ruby
    capture(:cat, release_path.join(".ruby-version"))
  end

  def prev_puma
    capture("cat #{prev_release_path}/Gemfile.lock | grep puma").split("\n").first
  end

  def current_puma
    capture("cat #{release_path}/Gemfile.lock | grep puma").split("\n").first
  end

  def puma_status
    capture("systemctl show -p ActiveState --value #{fetch :puma_service_name}")
  end

  def prev_release_path
    prev_release = capture(:ls, "-xt", releases_path).split[1]
    releases_path.join(prev_release)
  end

  def verify_puma_service_active
    seconds_to_wait = fetch :puma_active_timeout
    info "Waiting for up to #{seconds_to_wait}s for Puma to become active"
    while !puma_running? && seconds_to_wait.positive?
      sleep 1
      seconds_to_wait -= 1
    end
    if puma_running?
      info("Puma status: #{puma_status}")
    else
      error("Puma status: #{puma_status}. Manual intervention required.")
      warn("Check logs with:")
      warn("journalctl -u #{fetch :puma_service_name} -n 30 --no-pager")
      warn("tail -n 30 #{release_path.join('log', 'production.log')}")
    end
  end
end
