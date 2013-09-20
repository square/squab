require "squab"
require "faker"

def get_rand_elem(list)
  list[rand(list.length).to_i]
end

def make_events
  event_list = []
  time_base = Time.now.to_i - 25
  some_users = []
  some_urls = []
  some_sources = []
  some_events = []
  3.times do
    some_users.push(Faker::Internet.user_name)
  end
  3.times do
    some_urls.push(Faker::Internet.url)
  end
  3.times do
    some_sources.push(Faker::Internet.slug)
  end
  16.times do |i|
    event = Squab::Event.new(
      Faker::Lorem.sentence,
      get_rand_elem(some_urls),
      get_rand_elem(some_users),
      get_rand_elem(some_sources),
      time_base + i
    )
    some_events.push(event)
  end
  some_events
end

def events_to_yaml(event_list)
  ret_list = []
  event_list.each do |e|
    e_hash = e.to_h
    e_hash.delete(:id)
    ret_list.push(e_hash)
  end
  ret_list.to_yaml
end

def yaml_to_events(event_yaml)
  ret_list = []
  event_list = YAML.load(event_yaml)
  event_list.each do |e|
    new_event = Squab::Event.new(
                  e[:value],
                  e[:url],
                  e[:uid],
                  e[:source],
                  e[:date]
                )
    ret_list.push(new_event)
  end
  ret_list
end
