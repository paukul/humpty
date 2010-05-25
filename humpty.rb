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
    set :server, %w[mongrel thin webrick]

    before do
      set_server
    end

    get '/' do
      @queues = @server.queues
      @status = @server.status
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
      carrot.queue(params[:name]).delete
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

    def carrot
      Carrot.new(:host => @server.configuration["rabbitmq"]["host"])
    end

    helpers do
      include Sinatra::Partials
      def class_for_queue(queue)
        @message_threshold = queue_config[@server.id][queue["name"]].to_i rescue 0
        @message_threshold < queue["messages"].to_i ? "critical_queue" : nil
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
      Server.initialize unless Server.initialized?
      session["server"] = server_name = server || params["server"] || session["server"]
      @servers = Server.servers
      @server = Server[server_name]
    end
  end
end

Humpty::App.run! :port => 4567 if $0 == __FILE__
