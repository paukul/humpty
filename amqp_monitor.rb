require 'vendor/gems/environment'
require 'sinatra'
Bundler.require_env

class Server
  include HTTParty
  base_uri "http://localhost:9999"
  
  def self.queues
    requested_attributes = ["name", "durable", "auto_delete", "arguments", "messages_ready", "messages_unacknowledged", "messages_uncommitted", "messages", "acks_uncommitted", "consumers", "transactions", "memory"]
    puts "/queues/root/#{requested_attributes.join('/')}"
    get("/queues/root/#{requested_attributes.join('/')}")["queues"]
  end
end

get '/' do
  @queues = Server.queues
  haml :queues
end