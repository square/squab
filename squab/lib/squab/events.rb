require 'rubygems'
require 'squab/db'
require 'json'

module Squab
  class Events < Squab::DB
    def initialize(conn_string, opts={})
      @return_json = opts.include?(:json) ? opts[:json] : true
      super(conn_string)
    end

    def all(limit=1000)
      all_events = nil
      if limit == 0
        all_events = @events.all.sort_by { |event| event[:id] }
        all_events.reverse!
      else
        all_events = @events.limit(limit.to_i).reverse_order(:id)
      end
      format_rows(all_events)
    end

    # Wrap calls with this when you don't want JSON to return ever.
    # TODO: Redo the entire internal-returning-json-thing
    def with_no_json(&block)
      # Whatever the situation is on json, store it, and set it to false for
      # the period of this block call
      returner_type = @return_json
      @return_json = false

      ret_val = block.call

      # Put it back to whatever it was
      @return_json = returner_type
      ret_val
    end

    def event_slice(search_params)
      # Grab all events, or just a slice of events if there's
      # a time specified
      # TODO: Build this off the sequel data source so it's not
      #       a giant if/else
      with_no_json do
        if search_params.include?(:from) || search_params.include?(:to)
          from = search_params.delete(:from)
          to = search_params.delete(:to)
          if to.nil?
            newer_than(from)
          elsif from.nil?
            between(0, to)
          else
            between(from, to)
          end
        elsif search_params.include?(:fromId) || search_params.include?(:toId)
          from_id = search_params.delete(:fromId)
          to_id = search_params.delete(:toId)
          if to_id.nil?
            starting_at(from_id)
          elsif from_id.nil?
            between_ids(1, to_id)
          else
            between_ids(from_id, to_id)
          end
        else
          # If all the params nil or empty or 0 then return a limited set
          if search_params.all? {|_, v| v.to_i == 0}
            all(1000)
          else
            # We have some search params, so return everything
            all(0)
          end
        end
      end
    end

    def search_fields(search_params)
      search_params = keys_to_sym(search_params)
      ret_limit = search_params.delete(:limit)
      all_events = event_slice(search_params)

      # Filter out nils and empty strings up front
      # This allows the catch-all default-all to still work
      valid_search_params = {}
      search_params.each do |k,v|
        next if v.nil?
        next if v.empty?
        valid_search_params[k] = v
      end

      # Short circuit here and give back all events if there's no search
      # parameters
      if valid_search_params.empty?
        if ret_limit
          return all_events.limit(ret_limit)
        else
          return all_events
        end
      end

      ret_events = []

      all_events.each do |event|
        matched = false
        valid_search_params.each do |k, v|
          # Silently ignore bad search fields
          if event[k]
            if event[k].match(/#{v}/i)
              matched = true
            else
              matched = false
              # Stop looking, this is an AND search
              break
            end
          end
        end
        if matched
          ret_events.push(event)
        end
      end

      if ret_limit
        ret_events[0..(ret_limit.to_i - 1)]
      else
        ret_events
      end
    end

    # This now brokers between the new and old style search
    def search(pattern, fields=['value'])
      if pattern.kind_of?(Hash)
        format_rows(search_fields(pattern))
      elsif pattern.kind_of?(String)
        format_rows(search_text(pattern, fields))
      else
        format_rows(nil)
      end
    end

    # Old style search, one pattern, multiple fields
    def search_text(pattern, fields)
      all_events = with_no_json do
        all(0)
      end
      ret_events = []

      all_events.each do |event|
        event.each do |k, v|
          if fields.member?(k.to_s) or fields.member?('all')
            if v =~ /#{pattern}/i
              ret_events.push(event)
              break
            end
          end
        end
      end
      ret_events
    end

    def by_user(uid, limit=1000)
      user_events = @events.where(:uid => uid).reverse_order(:id).limit(limit)
      format_rows(user_events)
    end

    def by_source(source, limit=1000)
      source_events = @events.where(:source => source).reverse_order(:id).limit(limit)
      format_rows(source_events)
    end

    def by_id(id)
      single_event = @events.where(:id => id)
      format_rows(single_event)
    end

    def recent()
      all(50)
    end

    def delete(event_id)
    end

    def starting_at(event_id)
      new_events =  @events.where{id >= "#{event_id}"}.reverse_order(:id)
      format_rows(new_events)
    end

    def between_ids(start_id, end_id)
      events = @events.where(:id => start_id..end_id)
      format_rows(events)
    end

    def list_distinct(column)
      column = column.to_sym
      things = @events.select(column).distinct
      thing_list = things.map{|t| t[column]}
      # don't return nil, that's just silly
      thing_list.delete(nil)
      if @return_json
        "#{thing_list.to_json}\n"
      else
        thing_list
      end
    end

    def url_list()
      list_distinct(:url)
    end

    def source_list()
      list_distinct(:source)
    end

    def user_list()
      list_distinct(:uid)
    end

    def format_rows(rows)
      if @return_json
        rows_to_json(rows)
      else
        rows
      end
    end

    def rows_to_json(rows)
      ret_events = []
      unless rows.nil?
        rows.each do |row|
          cur_event = Squab::Event.new(row[:value],
                                       row[:url],
                                       row[:uid],
                                       row[:source],
                                       row[:date],
                                       row[:id])
          ret_events.push(cur_event)
        end
      end
      "#{ret_events.to_json}\n"
    end

    def newer_than(timestamp)
      new_events = @events.where{date >= "#{timestamp.to_s}"}.reverse_order(:id)
      format_rows(new_events)
    end

    def between(from, to)
      new_events = @events.where{date >= "#{from}"}.where{date <= "#{to}"}.reverse_order(:id)
      format_rows(new_events)
    end

    def add_event(event)
      if event.date.nil?
        now = Time.now.to_i
        event.date = now
      end
      @events.insert(:date => event.date,
                     :value => event.value,
                     :url => event.url,
                     :source => event.source,
                     :uid => event.uid,
                     :deleted => false)
      event.to_json
    end

    def keys_to_sym(old_hash)
      new_hash = {}
      old_hash.each do |k,v|
        new_hash[k.to_sym] = old_hash[k]
      end
      new_hash
    end
  end

  class Event
    attr_accessor :date, :value, :url, :uid, :id, :source
   
    def initialize(value, url, uid, source, date=nil, id=nil)
      @date = date
      @value = value
      @uid = uid
      @url = url
      @source = source
      @id = id
      @push = false
    end

    def to_h
      {
        date: @date,
        uid: @uid,
        value: @value,
        url: @url,
        source: @source,
        id: @id,
      }
    end

    def to_json(*a)
      self.to_h.to_json(*a)
    end
  end
end
