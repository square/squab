# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "squab-client"
  s.version     = "1.4.0"
  s.license     = "Apache 2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Grier Johnson"]
  s.email       = ["github@squareup.com"]
  s.summary     = "Squab client"
  s.description = "A client wrapper for the Squab API, also includes the CLI tool 'squawk' for quick message sending"
  s.homepage    = "http://github.com/square/squab"

  s.required_rubygems_version = ">= 1.3.6"

  s.executables = %W{ squawk }

  s.files        = Dir.glob('lib/*') + Dir.glob('bin/*') + %w(README.md)
  s.extra_rdoc_files = ["LICENSE.md"]
  s.rdoc_options = ["--charset=UTF-8"]
end

