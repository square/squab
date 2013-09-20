#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

module Squab
  class DB
    attr_accessor :events, :threadsafe

    def initialize(conn_string)
      @db = Sequel.connect(conn_string)
      if not @db.table_exists?('events')
        bootstrap
      end
      # SQLite is not threadsafe
      @threadsafe = @db.database_type != :sqlite
      @events = @db.from(:events)
    end

    def bootstrap
      @db.create_table :events do
          primary_key :id
          String :uid
          String :value
          String :url
          String :source
          Float :date
          Boolean :deleted
          index :uid
          index :date
          index :source
          index :deleted
      end
    end
  end
end

