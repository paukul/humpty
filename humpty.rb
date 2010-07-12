begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup
end
require 'sinatra/base'
Bundler.require

module Humpty
  class Error < StandardError; end

  class App < Sinatra::Base
    require 'server'
    require 'partials'

    enable :static
    disable :run

    set :public, File.expand_path('../public', __FILE__)
    set :queue_threshold_file, 'config/queue_thresholds.yml'
    set :sessions, true

    before do
      set_server
    end

    get '/' do
      @control = @server.control
      @queues = @server.queues
      haml :overview
    end

    get '/queues/?' do
      @queues = @server.queues
      haml :queues
    end

    get '/bindings' do
      @bindings = @server.bindings
      haml :bindings
    end

    get '/config' do
      @queues = @server.queues
      @config = queue_config[@server.id] || {}
      haml :config
    end

    get '/queues/:name/delete' do
      @server.queue(params[:name]).delete
      redirect '/'
    end

    post '/config' do
      queue_config.update(@server.id => params["queues"])
      File.open(options.queue_threshold_file, 'w') do |file|
        file.puts queue_config.to_yaml
      end
      redirect '/config'
    end

    get '/exchanges/?' do
      @exchanges = @server.exchanges.reject {|e| e["name"].blank? }
      haml :exchanges
    end

    helpers do
      include Sinatra::Partials
      def class_for_queue(queue)
        @message_threshold = queue_config[@server.id][queue["name"]].to_i rescue 0
        current_amount = queue["messages"].to_i
        if @message_threshold == 0 || @message_threshold >= current_amount
          nil
        else
          "critical_queue"
        end
      end

      def queue_config
        File.open(options.queue_threshold_file, "w") unless File.exists?(options.queue_threshold_file)
        @queue_config ||= (YAML.load_file(options.queue_threshold_file) || {})
      end
    end

    not_found do
      haml "#failbunny\n%img(src='img/bunny.jpg')"
    end

    def set_server(server = nil)
      @servers = Server.configurations.keys
      session["server"] = server_name = server || params["server"] || session["server"] || @servers.first
      begin
        @server = Server.new(server_name)
      rescue Server::ConfigurationException
        set_server(@servers.first)
      end
    end
  end
end

