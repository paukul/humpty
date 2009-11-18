require 'vendor/gems/environment'
require 'sinatra'
Bundler.require_env
require 'server'

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
  @config = queue_config
  haml :config
end

post '/config' do
  puts params.inspect
  File.open(options.queue_threshold_file, 'w') do |file|
    file.puts params["queues"].to_yaml
  end
  redirect '/config'
end

helpers do
  def class_for_queue(queue)
    queue_config["#{queue["name"]}_#{@server.id}"].to_i < queue["messages"].to_i ? "critical_queue" : nil
  end

  def queue_config
    File.open(options.queue_threshold_file, "w") unless File.exists?(options.queue_threshold_file)
    YAML.load_file(options.queue_threshold_file) || {}
  end
end

error Errno::ECONNREFUSED do
  haml 'Could not connect to the <a href="http://github.com/auser/alice">Alice</a> Server. Please make sure it\'s installed and running!'
end

not_found do
  haml "#failbunny\n%img(src='img/bunny.jpg')"
end