require 'spec_helper'

describe Squab::DB do
  before(:all) do
    @config = get_test_config
    @dbconn = @config['dbconn']
  end

  before do
    TestDBHelper.teardown(@dbconn)
  end

  it "Creates and bootstraps a database" do
    db = Squab::DB.new(@dbconn)
    expect(db.respond_to?('events')).to be true
    expect(db.events.all).to eq([])
  end
end

