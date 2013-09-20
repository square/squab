ENV['RACK_ENV'] = 'test'

require 'capybara/rspec'
require 'capybara/poltergeist'
require 'squab/web'

Capybara.javascript_driver = :poltergeist
Capybara.app = Squab::Web
