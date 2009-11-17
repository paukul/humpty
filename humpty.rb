require 'vendor/gems/environment'
require 'sinatra'
Bundler.require_env

class Server
  include HTTParty
  base_uri "http://localhost:9999"
  
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
    YAML.load_file('config/queue_thresholds.yml') || {}
  end
end