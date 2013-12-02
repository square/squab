require 'net/http'
require 'net/https'
require 'rubygems'
require 'json'
require 'yaml'
require 'etc'

class SendEventFailed < StandardError
end

module Squab
  class Client
    attr_accessor :source, :uid, :api_url, :ssl_verify
    attr_accessor :api_version_prefix, :events_prefix
    # Opts accepts
    # api => The API URL to hit
    # user => The user to report
    # source => the source to report
    def initialize(opts={})
      @source = get_my_source(opts[:source])
      @uid = get_my_user(opts[:user])
      parse_config
      @api_url = get_api(opts[:api] || @config[:api])
      @ssl_verify = @config['ssl_verify'] || true
      @api_version_prefix = @config['api_prefix'] || '/api/v1'
      @events_prefix = [@api_version_prefix, 'events'].join('/')
    end

    def send(event, url=nil)
      payload = {
        "uid" => @uid,
        "source" => @source,
        "value" => event,
        "url" => url,
      }.to_json
      header = {'Content-Type' => 'application/json'}
      req = Net::HTTP::Post.new(@events_prefix, initheader = header)
      req.body = payload
      try_count = 1
      begin
        http = Net::HTTP.new(@api_url.host, @api_url.port)
        http = setup_ssl(http) if @api_url.scheme == "https"
        response = http.request(req)
      rescue EOFError, Errno::ECONNREFUSED => e
        raise SendEventFailed, "Could not reach the Squab server"
      end
      response
    end

    def list_sources
      req = make_request('sources')
      get_req(req)
    end

    def list_users
      req = make_request('users')
      get_req(req)
    end

    def list_urls
      req = make_request('urls')
      get_req(req)
    end

    def get(max=5, since=nil)
      req = if since
        make_event_request("since/#{since.to_i}")
      else
        make_event_request("limit/#{max}")
      end
      get_req(req)
    end

    def get_from_event(event_num)
      req = make_event_request("starting/#{event_num}")
      get_req(req)
    end

    def get_from_user(username)
      req = make_event_request("user/#{username}")
      get_req(req)
    end

    def get_from_source(source)
      req = make_event_request("source/#{source}")
      get_req(req)
    end

    def simple_search(search_val)
      req = make_event_request("search/value/#{search_val}/limit/5")
      get_req(req)
    end

    def search(search_params)
      req = Net::HTTP::Post.new([ @events_prefix, 'search' ].join('/'))
      req.body = JSON.dump(search_params)
      get_req(req)
    end

    def get_api(url)
      url ? URI.parse(url) :  URI.parse(
        "http://squab/"
      )
    end

    def parse_config(file=nil)
      # Default
      config_file = file || '/etc/squab.yaml'
      # Instance override
      if File.exist?(config_file)
        @config = YAML.load(File.open(config_file).read)
      else
        @config = {}
      end
    end

    def get_my_source(source=nil)
      source || File.basename($PROGRAM_NAME)
    end

    def get_my_user(username=nil)
      username || Etc.getpwuid(Process.uid).name
    end

    private
    def setup_ssl(http)
      http.use_ssl = true
      http.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE 
      if @ssl_verify
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        $stderr.puts("Bypassing SSL verification, this should only happen "+
                     "during testing and development")
      end
      http.verify_depth = 5
      http
    end

    def get_req(req, full_req=false)
      http = Net::HTTP.new(@api_url.host, @api_url.port)
      http = setup_ssl(http) if @api_url.scheme == "https"
      resp = http.start { |h| h.request(req) }
      if full_req
        resp
      else
        resp.body
      end
    end

    def make_event_request(to)
      Net::HTTP::Get.new([ @events_prefix, to ].join('/'))
    end

    def make_request(to)
      Net::HTTP::Get.new([ @api_version_prefix, to ].join('/'))
    end
  end
end

# Old name space, deprecated and should be removed eventually
class SquabClient < Squab::Client
  def initialize(api_url=nil, source=nil, uid=nil)
    super(:api => api_url, :source => source, :user => uid)
  end
end

