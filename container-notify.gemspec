lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'container-notify/version'

Gem::Specification.new do |s|
  s.name          = 'container-notify'
  s.version       = ContainerNotify::VERSION
  s.authors       = ['Gordon Bleux']
  s.email         = ['UiP9AV6Y+containernotify@protonmail.com']

  s.summary       = 'Signal Docker containers upon filesystem changes.'
  s.description   = 'Watches docker volume mounts and dispatches signals ' \
                    'to selected docker containers.'
  s.homepage      = 'https://github.com/uip9av6y/container-notify'
  s.license       = 'MIT'

  all_files       = Dir.glob("{bin,lib}/**/*") 
  test_files      = Dir.glob("{spec}/**/*")

  all_files += %w[LICENSE.txt README.md container-notify.gemspec]

  s.files         = all_files - test_files
  s.test_files    = test_files
  s.executables   = %w[container-notify]
  s.require_paths = ['lib']

  s.required_ruby_version = '~> 2.2'

  s.add_development_dependency 'bundler', '~> 1.16'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-console'

  s.add_dependency 'docker-api', '~> 1.34', '>= 1.34.0'
  s.add_dependency 'listen', '~> 3.1', '>= 3.1.0'
end
