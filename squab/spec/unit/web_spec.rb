require 'spec_helper'

describe "The Squab API" do
  include Rack::Test::Methods

  def app
    Squab::Web
  end

  before(:all) do
    @start_time = Time.now.to_i
    @config = get_test_config
    @dbconn = @config["dbconn"]
    TestDBHelper.teardown(@dbconn)
  end

  it "posts messages to squab" do
    event1 = { value: "first message",
               url: nil,
               uid: "test",
               source: "rspec" }.to_json
    event2 = { value: "second message",
               url: "http://example.com",
               uid: "tester",
               source: "rspec-test" }.to_json
    event3 = { value: "last message",
               url: nil,
               uid: "tester",
               source: "rspec",
               date: @start_time+60 }.to_json
    # Run it twice for some bulk
    2.times do
      post '/api/v1/events', event1, "CONTENT_TYPE" => "application/json"
      expect(last_response).to be_ok
      post '/api/v1/events', event2, "CONTENT_TYPE" => "application/json"
      expect(last_response).to be_ok
      post '/api/v1/events', event3, "CONTENT_TYPE" => "application/json"
      expect(last_response).to be_ok
    end
  end

  it "gives a list of events" do
    get '/api/v1/events'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events[0]["value"]).to eq "last message"
    expect(events[1]["value"]).to eq "second message"
    expect(events[2]["value"]).to eq "first message"
  end

  it "gives a list of recent events" do
    get '/api/v1/events/recent'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to be <= 50
    expect(events[0]["value"]).to eq "last message"
  end

  it "gives a list of events of a limited number" do
    get '/api/v1/events/limit/2'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
    expect(events[0]["value"]).to eq "last message"
  end

  it "gives an event by id" do
    get '/api/v1/events/3'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 1
    expect(events[0]["value"]).to eq "last message"
  end

  it "gives all events after a provided id" do
    get '/api/v1/events/starting/2'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 5
    expect(events[0]["value"]).to eq "last message"
  end

  it "gives events between, and including, two ids" do
    get '/api/v1/events/starting/2/to/4'
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 3
    expect(events[0]["value"]).to eq "second message"
  end

  it "gives events after a certain date" do
    get "/api/v1/events/since/#{@start_time}"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 6
    expect(events[0]["value"]).to eq "last message"
  end

  it "gives events between two times" do
    get "/api/v1/events/since/#{@start_time}/to/#{@start_time+1}"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to be > 0
    expect(events.length).to be <= 6
  end

  it "gives all the events by a user" do
    get "/api/v1/events/user/tester"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 4
    expect(events[0]["value"]).to eq "last message"
    expect(events[1]["value"]).to eq "second message"
    expect(events[2]["value"]).to eq "last message"
  end

  it "gives all the events by a source" do
    get "/api/v1/events/source/rspec-test"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
    expect(events[0]["value"]).to eq "second message"
    expect(events[1]["value"]).to eq "second message"
  end

  it "searches based on field and pattern" do
    get "/api/v1/events/search/value/second"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to be 2
    expect(events[0]["value"]).to eq "second message"
    expect(events[1]["value"]).to eq "second message"

    # case insensitive and partial matching
    get "/api/v1/events/search/uid/TEST"
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 6
  end

  it "allows an empty search to be the same as all" do
    json = JSON.dump({})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 6
  end
    
  it "searches multiple fields with a single pattern" do
    json = JSON.dump({ fields: ['uid', 'source'], pattern: 'test'})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 6
  end
    
  it "searches multiple fields with different patterns" do
    json = JSON.dump({ uid: 'tester', source: 'rspec' })
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 4
  end

  it "searches multiple fields after a certain time" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', from: @start_time})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 4
  end

  it "searches multiple fields before a certain time" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', from: @start_time+30})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
  end

  it "searches multiple fields inside a time slice" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', from: @start_time,
                       to: @start_time + 30})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
  end

  it "searches multiple fields after a certain id" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', fromId: 4})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
  end

  it "searches multiple fields before a certain id" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', toId: 4})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
  end

  it "searches multiple fields inside an id slice" do
    json = JSON.dump({ uid: 'tester', source: 'rspec', fromId: 2,
                       toId: 4})
    post "/api/v1/events/search", json
    expect(last_response).to be_ok
    events = nil
    expect{events = JSON.parse(last_response.body)}.to_not raise_error
    expect(events).to_not be nil
    expect(events.length).to eq 2
  end

  it "gives a list of users" do
    get "/api/v1/users"
    expect(last_response).to be_ok
    list = nil
    expect{list = JSON.parse(last_response.body)}.to_not raise_error
    expect(list).to_not be nil
    expect(list.length).to eq 2
    list.sort!
    expect(list[0]).to eq "test"
    expect(list[1]).to eq "tester"
  end

  it "gives a list of sources" do
    get "/api/v1/sources"
    expect(last_response).to be_ok
    list = nil
    expect{list = JSON.parse(last_response.body)}.to_not raise_error
    expect(list).to_not be nil
    expect(list.length).to eq 2
    list.sort!
    expect(list[0]).to eq "rspec"
    expect(list[1]).to eq "rspec-test"
  end

  it "gives a list of urls" do
    get "/api/v1/urls"
    expect(last_response).to be_ok
    list = nil
    expect{list = JSON.parse(last_response.body)}.to_not raise_error
    expect(list).to_not be nil
    expect(list.length).to eq 1
    list.sort!
    expect(list[0]).to eq "http://example.com"
  end

  it "returns status as 200 unless there is a down file" do
    get "/_status"
    conf_dir = File.dirname(ENV['SQUAB_CONFIG'])
    down_file = File.join(conf_dir, 'down')
    File.unlink(down_file) if File.exist?(down_file)
    expect(last_response).to be_ok
    File.open(down_file, 'a+') do |fh|
      fh.write('down')
    end
    get "/_status"
    expect(last_response.status).to eq 500
    File.unlink(down_file)
  end
end

