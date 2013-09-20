# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "squab"
  s.version     = "1.3.2"
  s.license     = "Apache 2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Grier Johnson"]
  s.email       = ["github@squareup.com"]
  s.summary     = "A simple event stream database and visualizer"
  s.description = "A rest API fronted database and web based front-end around a event database.  Useful for visualizing and tracking events in a time-stream style format."
  s.homepage    = "http://github.com/square/squab"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency("sinatra", ">=1.3.3")
  s.add_dependency("sinatra-contrib", ">=1.3.3")
  s.add_dependency("rack", ">=1.4.1")
  s.add_dependency("sequel", ">=3.40.0")
  s.add_dependency("sqlite3", ">=1.3.6")
  s.add_dependency("json", ">=1.7.4")
  s.add_dependency("thin", ">=1.5.0")
  s.default_executable = %q{squab}
  s.executables = %W{ squab }

  s.files        = Dir.glob('lib/**/*') + Dir.glob('bin/*') + Dir.glob('public/**/*') + Dir.glob('*.yaml') + %w(README.md)
  s.extra_rdoc_files = ["LICENSE.md"]
  s.rdoc_options = ["--charset=UTF-8"]
end

