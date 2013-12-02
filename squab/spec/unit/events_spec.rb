require 'spec_helper'

describe Squab::Event do
  it "Makes an event object" do
    se = Squab::Event.new('Some string', 'http://foo.com', 'test', 'rspec')
    expect(se.value).to eq 'Some string'
    expect(se.url).to eq 'http://foo.com'
    expect(se.uid).to eq 'test'
    expect(se.source).to eq 'rspec'
  end

  it "Converts to a Hash" do
    se = Squab::Event.new('Some string', 'http://foo.com', 'test', 'rspec')
    se_hash = se.to_h
    expect(se_hash.kind_of?(Hash)).to be true
    expect(se_hash[:source]).to eq 'rspec'
  end

  it "Converts to JSON" do
    se = Squab::Event.new('Some string', 'http://foo.com', 'test', 'rspec')
    se_json = JSON.parse(se.to_json)
    expect(se_json['value']).to eq "Some string"
    expect(se_json['url']).to eq "http://foo.com"
    expect(se_json['uid']).to eq "test"
    expect(se_json['source']).to eq "rspec"
  end
end

describe Squab::Events do
  before(:all) do
    @config = get_test_config
    @events = get_events
    TestDBHelper.teardown(@config['dbconn'])
  end

  before do
    @dbconn = @config['dbconn']
    @squab = Squab::Events.new(@dbconn, json: false)
    @events.each do |e|
      @squab.add_event(e)
    end
  end

  after do
    TestDBHelper.teardown(@config['dbconn'])
  end

  it "adds events to the database" do
    # Since we're adding events, do this in a different squab
    tmp_db = TestDBHelper.tmp_db_conn
    local_squab = Squab::Events.new(tmp_db, json: false)
    @events.each do |e|
      expect{local_squab.add_event(e)}.to_not raise_error
    end
    TestDBHelper.teardown(tmp_db)
  end

  it "gets all events from the database" do
    all_items = @squab.all(0)
    expect(all_items.length).to eq @events.length
    # They come back in reverse order
    retr = all_items[-1]
    orig = @events[0].to_h
    expect(retr[:source]).to eq orig[:source]
    expect(retr[:uid]).to eq orig[:uid]
    expect(retr[:url]).to eq orig[:url]
    expect(retr[:value]).to eq orig[:value]
  end

  it "gets a particular event from the database" do
    retr = @squab.by_id(6).all
    expect(retr.length).to eq 1
    retr = retr.first
    # Off by one
    orig = @events[5].to_h
    expect(retr[:source]).to eq orig[:source]
    expect(retr[:uid]).to eq orig[:uid]
    expect(retr[:url]).to eq orig[:url]
    expect(retr[:value]).to eq orig[:value]
  end

  it "gets events in a range of id" do
    retr = @squab.between_ids(4, 8).all
    expect(retr.length).to eq 5
    expect(retr[0][:value]).to eq @events[3].to_h[:value]
  end

  it "gets recent events from the database" do
    # build a local DB that has 64 items in it
    tmp_db = TestDBHelper.tmp_db_conn
    local_squab = Squab::Events.new(tmp_db, json: false)
    4.times do
      @events.each do |e|
        local_squab.add_event(e)
      end
    end
    retr = local_squab.recent.all
    expect(retr.length).to eq 50
    expect(retr.first[:value]).to eq @events[-1].to_h[:value]
    TestDBHelper.teardown(tmp_db)
  end

  it "gets events between a certain time" do
    start = @events[2].to_h[:date]
    endt = @events[5].to_h[:date]
    retr = @squab.between(start, endt).all
    expect(retr.length).to eq 4
    expect(retr.first[:value]).to eq @events[5].to_h[:value]
  end

  it "gets events since a certain time" do
    start = @events[10].to_h[:date]
    retr = @squab.newer_than(start).all
    expect(retr.length).to eq 6
  end

  it "gets all the events from a user" do
    # user is raphaelle.hettinger
    user = @events[0].to_h[:uid]
    retr = @squab.by_user(user).all
    expect(retr.length).to be 6
    users = Set.new(retr.map{ |i| i[:uid]}).to_a
    expect(users.length).to eq 1
    expect(users.first).to eq user
  end

  it "gets all the events from a source" do
    # source is pariatur.nemo
    source = @events[0].to_h[:source]
    retr = @squab.by_source(source).all
    expect(retr.length).to eq 6
    sources = Set.new(retr.map{ |i| i[:source]}).to_a
    expect(sources.length).to eq 1
    expect(sources.first).to eq source
  end

  it "searches for events with a particular content" do
    search_value = @events[2].to_h[:value]
    retr = @squab.search(search_value)
    expect(retr.length).to eq 1
    expect(retr.first[:value]).to eq search_value
  end

  it "searches for events with a particular user" do
    search_user = @events[4].to_h[:uid]
    retr = @squab.search(search_user, ["uid"])
    expect(retr.length).to eq 4
    expect(retr.first[:uid]).to eq search_user
  end

  it "searches for events with a particular source" do
    search_source = @events[0].to_h[:source]
    retr = @squab.search(search_source, ["source"])
    expect(retr.length).to eq 6
    expect(retr.first[:source]).to eq search_source
  end

  it "searches for events with a particular url" do
    search_url = @events[0].to_h[:url]
    retr = @squab.search(search_url, ["url"])
    expect(retr.length).to eq 4
    expect(retr.first[:url]).to eq search_url
  end

  it "search for events with multple search columns" do
    search_value = "qui"
    retr = @squab.search(search_value, ["value", "uid", "source"])
    expect(retr.length).to be 3
  end

  it "returns events since a starting time based on time search params" do
    start = @events[-3].to_h[:date]
    search_params = { from: start }
    retr = @squab.event_slice(search_params).all
    expect(retr.length).to eq 3
  end

  it "returns a slice of events based on time search params" do
    start = @events[0].to_h[:date]
    finish = @events[4].to_h[:date]
    search_params = { from: start, to: finish }
    retr = @squab.event_slice(search_params).all
    expect(retr.length).to eq 5
  end

  it "returns events since a starting id based on id search params" do
    from_id = @events.length - 2
    search_params = { fromId: from_id }
    retr = @squab.event_slice(search_params).all
    expect(retr.length).to eq 3
  end

  it "returns a slice of events based on id search params" do
    search_params = { fromId: 1, toId: 5 }
    retr = @squab.event_slice(search_params).all
    expect(retr.length).to eq 5
  end

  it "searches multiple columns with different patterns" do
    user_value = @events[0].to_h[:uid]
    source_value = @events[0].to_h[:source]
    # Often times we'll be converting from json, so don't test
    # with symbols here
    search_params = { 'uid' => user_value, 'source' => source_value }
    retr = @squab.search(search_params)
    retr.each do |e|
      expect(e[:uid]).to eq user_value
      expect(e[:source]).to eq source_value
    end
  end

  it "limits the number of events that come back from a search" do
    user_value = @events[0].to_h[:uid]
    search_params = { 'uid' => user_value, 'limit' => 2 }
    retr = @squab.search(search_params)
    expect(retr.length).to eq 2
    retr.each do |e|
      expect(e[:uid]).to eq user_value
    end
  end

  it "limits the number of events that come back from an empty search" do
    search_params = { 'limit' => 6 }
    retr = @squab.search(search_params).all
    expect(retr.length).to eq 6
  end

  it "gets a list of all sources" do
    sources = @squab.source_list.sort
    uniq_orig = Set.new(@events.map{|e| e.to_h[:source]}).to_a.sort
    expect(sources).to eq uniq_orig
  end

  it "gets a list of all users" do
    users = @squab.user_list.sort
    uniq_orig = Set.new(@events.map{|e| e.to_h[:uid]}).to_a.sort
    expect(users).to eq uniq_orig
  end

  it "gets a list of all urls" do
    urls = @squab.url_list.sort
    uniq_orig = Set.new(@events.map{|e| e.to_h[:url]}).to_a.sort
    expect(urls).to eq uniq_orig
  end
end

# This section is specifically for search bugs/regressions
describe Squab::Events do
  before(:all) do
    @config = get_test_config
    TestDBHelper.teardown(@config['dbconn'])
  end

  before do
    @dbconn = @config['dbconn']
    @squab = Squab::Events.new(@dbconn, json: false)
  end

  after do
    TestDBHelper.teardown(@config['dbconn'])
  end

  it "passing nil or empty-strings as search params is like not passing those params at all" do
    broken = Squab::Event.new(
      'Mauris accumsan lacus nec dolor',
      'http://auerconnelly.biz/alyon_johnston',
      'arlie.simonis',
      nil,               # nil source
    )
    working = Squab::Event.new(
      'Mauris accumsan lacus nec dolor',
      'http://auerconnelly.biz/alyon_johnston',
      'arlie.simonis',
      'asdfasdf',
    )
    @squab.add_event(broken)
    @squab.add_event(working)

    search_params = { :source => 'asdfasdf' }
    nil_params = { :value => nil, :source => 'asdfasdf', :uid => nil, :url => nil }
    empty_params = { :value => '', :source => 'asdfasdf', :uid => '', :url => '' }

    result = @squab.search(search_params)
    expect(@squab.search(nil_params)).to eq result
    expect(@squab.search(empty_params)).to eq result
  end
end
