require 'json'
require 'pathname'
require 'sinatra'
require 'sinatra/config_file'
require 'squab'

module Squab
  class Web < Sinatra::Base
    register Sinatra::ConfigFile
    
    # Set up some defaults we include with the package
    default_config = File.join(File.dirname(__FILE__), '../../defaults.yaml')
    config_file default_config

    # Check for user provided defaults
    config = ENV['SQUAB_CONFIG'] || '/etc/squab.yaml'
    if File.exists?(config)
      config_file config
      set :config, config
    else
      set :config, default_config
    end

    # Take whatever the connect string is from the config and feed it
    # to Squab::Events and make an object
    set :dbconn, Squab::Events.new(settings.dbconn)

    # Some database backends are not threadsafe, use a lock if squab
    # doesn't report they are threadsafe
    if not settings.dbconn.threadsafe
      enable :lock
    end

    unless settings.root.start_with?('/')
      # Allow relative pathing
      set :root, 
        File.expand_path(File.join(File.dirname(__FILE__), settings.root))
    end

    enable :logging
    enable :dump_errors
    disable :raise_errors

    configure :development do
      # 0 is debug level
      set :logging, 0
      enable :show_exceptions
    end

    helpers do
      def bad_request
        status 400
        redirect "api.html"
      end
      def safe_db(&block)
        begin
          block.call
        rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
          $stderr.puts e
          exit!
        end
      end
      def get_json_body(request)
        data = nil
        begin
          request.body.rewind
          data = JSON.parse request.body.read
          logger.debug(data.to_s)
        rescue JSON::ParserError
          request.body.rewind
          logger.warn("Bad JSON Body: " + request.body.read)
          logger.debug("Bad Request: " + request.inspect.to_s)
        end
        data
      end
    end

    get '/' do
      File.read(File.join(settings.public_folder, 'events.html'))
    end

    get '/api/v1/events' do
      safe_db do
        settings.dbconn.all
      end
    end

    get '/api/v1/events/recent' do
      safe_db do
        settings.dbconn.recent
      end
    end

    get '/api/v1/events/limit/:limit' do |limit|
      safe_db do
        settings.dbconn.all(limit)
      end
    end

    get '/api/v1/events/:id' do |id|
      safe_db do
        settings.dbconn.by_id(id)
      end
    end

    get '/api/v1/events/starting/:id' do |id|
      safe_db do
        settings.dbconn.starting_at(id)
      end
    end

    get '/api/v1/events/starting/:start_id/to/:end_id' do |start_id, end_id|
      safe_db do
        settings.dbconn.between_ids(start_id, end_id)
      end
    end

    get '/api/v1/events/since/:date' do |date|
      date = date.to_i
      now = Time.now.to_i
      if date > now
        date = now
      end
      safe_db do
        settings.dbconn.newer_than(date)
      end
    end

    get '/api/v1/events/since/:start_date/to/:end_date' do |start_date, end_date|
      start_date = start_date.to_i
      end_date = end_date.to_i
      now = Time.now.to_i
      if end_date > now
        end_date = now
      end
      if start_date > end_date
        []
      else
        safe_db do
          settings.dbconn.between(start_date, end_date)
        end
      end
    end

    get '/api/v1/events/user/:user' do |user|
      safe_db do
        settings.dbconn.by_user(user)
      end
    end

    get '/api/v1/events/source/:source' do |source|
      safe_db do
        settings.dbconn.by_source(source)
      end
    end

    get '/api/v1/events/search/:field/:pattern' do |field, pattern|
      safe_db do
        settings.dbconn.search(pattern, [field])
      end
    end

    get '/api/v1/events/search/:field/:pattern/limit/:limit' do |field, pattern, limit|
      safe_db do
        settings.dbconn.search({field => pattern, :limit => limit})
      end
    end

    get '/api/v1/users' do
      safe_db do
        settings.dbconn.user_list
      end
    end

    get '/api/v1/urls' do
      safe_db do
        settings.dbconn.url_list
      end
    end

    get '/api/v1/sources' do
      safe_db do
        settings.dbconn.source_list
      end
    end

    post '/api/v1/events' do
      data = get_json_body(request)
      return 400 unless data.kind_of?(Hash)
      safe_db do
        e = settings.dbconn

        new_event = Event.new(data['value'],
                              data['url'],
                              data['uid'],
                              data['source'],
                              data['date'])

        "#{e.add_event(new_event)}\n"
      end
    end

    post '/api/v1/events/search' do
      data = get_json_body(request)
      return 400 unless data.kind_of?(Hash)
      safe_db do
        if data.has_key?('fields') && data.has_key?('pattern')
          settings.dbconn.search(data["pattern"], data["fields"])
        else
          settings.dbconn.search(data)
        end
      end
    end

    get '/_status' do
      if File.exists?(File.join(File.dirname(settings.config), ('down')))
        500
      else
        200
      end
    end

    get '/api' do
      redirect "api.html"
    end

    get '*' do
      File.read(File.join(settings.public_folder, 'events.html'))
    end
  end
end
