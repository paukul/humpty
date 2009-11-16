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
end

get '/' do
  redirect "/queues"
end

get '/queues/?' do
  @queues = Server.queues
  haml :queues
end

get '/bindings' do
  @bindings = Server.bindings
  haml :bindings
end