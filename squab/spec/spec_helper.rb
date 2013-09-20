#$:.push(File.dirname(__FILE__))
ENV['RACK_ENV'] = 'test'
ENV['SQUAB_CONFIG'] = File.join(File.dirname(__FILE__), 'test_config.yaml')

require "squab"
require "squab/web"
require "support/events"
require "helper/db"
require "tempfile"
require "rack/test"

def get_test_config
  my_loc = File.dirname(__FILE__)
  YAML.load(File.open(File.join(my_loc, 'test_config.yaml')).read)
end

def get_events
  my_loc = File.dirname(__FILE__)
  event_yaml = File.open(File.join(my_loc, 'support', 'events.yaml')).read
  yaml_to_events(event_yaml)
end

