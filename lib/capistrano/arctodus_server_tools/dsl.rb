module Capistrano::ArctodusServerTools::DSL
  def monit_status
    capture("systemctl show -p ActiveState --value #{fetch :monit_service_name}")
  end

  def monit_running?
    monit_status == 'active'
  end

  def ruby_updated?
    current_ruby != prev_ruby
  end

  def puma_updated?
    current_puma != prev_puma
  end

  def stringio_updated?
    current_stringio != prev_stringio
  end

  def puma_running?
    puma_status == 'active'
  end

  def prev_ruby
    capture(:cat, prev_release_path.join(".ruby-version"))
  rescue SSHKit::Command::Failed => e
    warn("Checking previous ruby version failed:")
    e.message.to_s.split("\n").each(&method(:warn))
    warn("Falling back to v0.0.0")
    "0.0.0"
  end

  def current_ruby
    capture(:cat, release_path.join(".ruby-version"))
  end

  def prev_puma
    find_gem_version(path: prev_release_path, gem_name: "puma")
  end

  def current_puma
    find_gem_version(path: release_path, gem_name: "puma")
  end

  def prev_stringio
    find_gem_version(path: prev_release_path, gem_name: "stringio")
  end

  def current_stringio
    find_gem_version(path: release_path, gem_name: "stringio")
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

  def find_gem_version(path:, gem_name:)
    regex = '^\s{4}' + gem_name + ' \([0-9]+\.[0-9]+(\.[0-9]+)?\)'
    result = capture("cat #{path}/Gemfile.lock | grep -E '#{regex}' || true")
    if result == ""
      info result
    end
    result
  end
end
