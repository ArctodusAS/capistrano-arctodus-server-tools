Gem::Specification.new do |s|
  s.name = 'capistrano-arctodus-server-tools'
  s.version = "0.0.1"
  s.date = %q{2024-05-13}
  s.summary = 'capistrano arctodus server tools'
  s.authors = 'Bjørn Trondsen'
  s.add_dependency "capistrano", "~> 3.0"
  s.files = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.add_dependency 'tty-spinner', '~> 0.9.3'
end
