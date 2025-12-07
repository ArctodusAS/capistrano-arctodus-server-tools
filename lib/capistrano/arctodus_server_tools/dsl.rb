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
    @cached_gemfiles ||= {}
    unless @cached_gemfiles[path]
      @cached_gemfiles[path] = capture("cat #{path}/Gemfile.lock || true")
    end
    regex = /^\s{4}#{Regexp.escape(gem_name)} \((\d+\.\d+(?:\.\d+))?\)/
    @cached_gemfiles[path].match(/#{regex}/)&.captures&.first
  end

  def updated_default_gems
    current_ruby_default_gems.select do |gem_name|
      find_gem_version(path: prev_release_path, gem_name: gem_name) != find_gem_version(path: release_path, gem_name: gem_name)
    end
  end

  def current_ruby_default_gems
    require "net/http"
    ruby_version = RUBY_VERSION.split(".")[0..1].join(".")
    default_gems = []
    endpoint = URI("https://stdgems.org/default_gems.json")
    response = Net::HTTP.start(endpoint.host, endpoint.port, read_timeout: 5, open_timeout: 5, use_ssl: endpoint.scheme == 'https') do |http|
        http.get(endpoint)
      end
    gem_data = JSON.parse(response.body)
    gem_data["gems"].each do |gem_info|
      default_gems << gem_info["gem"] if gem_info["versions"].keys.include?(ruby_version)
    end
    default_gems
  rescue StandardError => e
    error("Fetching default gems failed: #{e.message}. If a default gem was updated, Puma will not restart correctly.")
    []
  end
end
