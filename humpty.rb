begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'sinatra'
Bundler.require
require 'server'
require 'partials'

class Humpty < Sinatra::Base
  set :queue_threshold_file, 'config/queue_thresholds.yml'
  set :sessions, true

  before do
    @servers = Server.configurations.keys
    server_name = params["server"] || session["server"] || @servers.first
    session["server"] = server_name
    @server = Server.new(server_name)
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

  error Errno::ECONNREFUSED do
    haml 'Could not connect to the <a href="http://github.com/auser/alice">Alice</a> Server. Please make sure it\'s installed and running!'
  end

  error do
    haml "%strong Something unexpected happened\n#exception #{request.env['sinatra.error'].message}"
  end

  not_found do
    haml "#failbunny\n%img(src='img/bunny.jpg')"
  end
end
