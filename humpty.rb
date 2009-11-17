require 'vendor/gems/environment'
require 'sinatra'
Bundler.require_env

def config
  begin
    @config ||= YAML.load_file('config/config.yml')
  rescue Errno::ENOENT
    puts "Please create the config.yml file in the config directory"
    exit 1
  end
end


class Server
  include HTTParty
  base_uri "#{config["alice"]["base_url"]}:#{config["alice"]["port"]}"

  def self.queues
    requested_attributes = %w(name durable auto_delete arguments messages_ready messages_unacknowledged messages_uncommitted messages acks_uncommitted consumers transactions memory)
    get("/queues/root/#{requested_attributes.join('/')}")["queues"]
  end

  def self.bindings
    get("/bindings")["bindings"]
  end

  def self.control
    get("/control")
  end
end

get '/' do
  @control = Server.control
  @queues = Server.queues
  haml :overview
end

get '/queues/?' do
  @queues = Server.queues
  haml :queues
end

get '/bindings' do
  @bindings = Server.bindings
  haml :bindings
end

get '/config' do
  @queues = Server.queues
  @config = queue_config
  haml :config
end

post '/config' do
  File.open('config/queue_thresholds.yml', 'w') do |file|
    file.puts params["queues"].to_yaml
  end
  redirect '/config'
end

helpers do
  def class_for_queue(queue)
    queue_config[queue["name"]].to_i < queue["messages"].to_i ? "critical_queue" : nil
  end

  def queue_config
    YAML.load(File.open('config/queue_thresholds.yml', "w+")) || {}
  end
end

error Errno::ECONNREFUSED do
  haml 'Could not connect to the <a href="http://github.com/auser/alice">Alice</a> Server. Please make sure it\'s installed and running!'
end