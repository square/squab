# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "squab-bot"
  s.version     = "1.3.2"
  s.license     = "Apache 2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Grier Johnson"]
  s.email       = ["github@squareup.com"]
  s.summary     = "An IRC interface to Squab"
  s.description = "An IRC bot that allows reading and posting to Squab"
  s.homepage    = "http://github.com/square/squab"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "isaac"
  s.add_dependency "squab-client"
  s.add_dependency "rangeclient"
  s.default_executable = %q{squab-bot}
  s.executables = %W{ squab-bot }

  s.files        = Dir.glob('lib/*') + Dir.glob('bin/*') + %w(README.md)
  s.extra_rdoc_files = ["LICENSE.md"]
  s.rdoc_options = ["--charset=UTF-8"]
end

