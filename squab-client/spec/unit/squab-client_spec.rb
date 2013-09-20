require 'spec_helper'
require 'ostruct'

describe "Squab::Client" do
  before(:all) do
    @sc = Squab::Client.new(api: "http://localhost:8082",
                            source: "test-source",
                            user: "test-user")
    @myself = @sc.get_my_user
    @sc_old = SquabClient.new("http://localhost:8082", nil, 'fake-user')
  end

  it 'creates a client with sane defaults' do
    sc = Squab::Client.new()
    # OSS: Alter this before upstream
    expect(sc.api_url.to_s).to eq "http://squab/"
    expect(sc.source).to eq "rspec"
    expect(sc.uid).to eq @myself
  end

  it 'sends events to squab', :vcr do
    expect{@sc.send("testing squab")}.to_not raise_error()
    expect{@sc_old.send("testing old squab")}.to_not raise_error()
  end

  it 'sends events to squab with a URL', :vcr do
    expect{@sc.send("testing squab with url", "http://example.com")}.to_not raise_error()
  end

  it 'retrieves a list of sources', :vcr do
    sources = @sc.list_sources
    expect(sources).to include('test-source')
    expect(sources).to include('rspec')
  end

  it 'retrieves a list of users', :vcr do
    users = @sc.list_users
    expect(users).to include('test-user')
    expect(users).to include('fake-user')
  end

  it 'retrieves a list of urls', :vcr do
    urls = @sc.list_urls
    expect(urls).to include('http://example.com')
  end

  it 'gets recent events', :vcr do
    events = JSON.parse(@sc.get)
    expect(events.first['value']).to eq "testing squab with url"
    expect(events.last['value']).to eq "testing squab"
  end

  it 'gets events from an id to current', :vcr do
    events = @sc.get_from_event(2)
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing squab with url"
    expect(events.last['value']).to eq "testing old squab"
  end

  it 'gets events from a specific user', :vcr do
    events = @sc.get_from_user('fake-user')
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing old squab"
    events = @sc.get_from_user('test-user')
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing squab with url"
  end

  it 'gets events from a specific source', :vcr do
    events = @sc.get_from_source('rspec')
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing old squab"
    events = @sc.get_from_source('test-source')
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing squab with url"
  end

  it 'does a simple search by value', :vcr do
    events = @sc.simple_search('old')
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing old squab"
    expect(events.length).to be <= 5
  end

  it 'does a full search', :vcr do
    events = @sc.search({:value => "old"})
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing old squab"
    events = @sc.search({:source => "test-source"})
    events = JSON.parse(events)
    expect(events.first['value']).to eq "testing squab with url"
  end
end
