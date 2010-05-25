require 'intruder'

module Humpty
  class Server
    class ConfigurationException < Error; end
    include Intruder
    attr_reader :id

    @@initialized = false
    @@servers = {}

    def self.initialize
      configurations.keys.each do |s|
        begin
          @@servers[s] = Server.new(s)
        rescue Server::ConfigurationException
          #
        end
      end
      @@initialized = true
    end

    def self.[](server_name = nil)
      server_name ? @@servers[server_name] : @@servers.first[1]
    end

    def self.servers
      @@servers.keys
    end

    def self.initialized?
      @@initialized
    end

    def initialize(id)
      @id = id
      cookie = configuration["cookie"] || File.read(File.expand_path('~/.erlang.cookie'))

      @node = Node.new("humpty_#{rand(1000)}", cookie)
      @node.connect("rabbit@#{configuration["rabbitmq"]["host"]}")
    end

    def queues
      arg = Term.encode([Binary.new("/")])
      queue_terms = @node.mod('rabbit_amqqueue').info_all(arg).to_a
      queues = []
      while queue_term = queue_terms.pop do
        queue_term = queue_term.to_a
        queue_hash = {}
        identifier = queue_term.shift
        queue_hash["name"] = convert(identifier[1][3])
        queue_hash["vhost"] = convert(identifier[1][1])
        queue_term.inject(queue_hash) do |ret, item|
          ret[item[0].to_s] = convert(item[1])
          ret
        end
        queues << queue_hash
      end
      queues
    end

    def bindings
      arg = Term.encode([Binary.new("/")])
      @node.mod('rabbit_exchange').list_bindings(arg).to_a.map do |binding|
        binding = binding.to_a
        exchange_identifier = binding.shift
        queue_identifier = binding.shift
        {
          "queue" => {
            "name" => convert(queue_identifier[3]),
            "vhost" => convert(queue_identifier[1])
          },
          "exchange" => {
            "name" => convert(exchange_identifier[3]),
            "vhost" => convert(exchange_identifier[1])
          },
          "key" => convert(binding[0]),
          "wtfisthis" => convert(binding[1])
        }
      end
    end

    def status
      result = @node.mod('rabbit').status(Term.encode([]))
      result.inject({}) {|ret,val| ret[val[0].to_s] = convert(val[1]); ret} # SUPERDRY!!! ...not
    end

    def self.configurations
      begin
        YAML.load_file('config/config.yml')
      rescue Errno::ENOENT
        puts "Please create the config.yml file in the config directory"
        exit 1
      end
    end

    def exchanges
      arg = Term.encode([Binary.new("/")])
      result = @node.mod('rabbit_exchange').info_all(arg).to_a
      result.map do |exchange|
        exchange = exchange.to_a
        exchange_identifier = exchange.shift
        exchange_hash = {
          "name" => convert(exchange_identifier[1][3]),
          "vhost" => convert(exchange_identifier[1][1])
        }
        exchange.inject(exchange_hash) {|ret,val| ret[val[0].to_s] = convert(val[1]); ret} # SUPERDRY!!! ...not
      end
    end

    def configuration
      @configuration ||= begin
         config = self.class.configurations[self.id]
         raise ConfigurationException.new("Server #{id} not configured") unless config
         config
      end
    end

    def to_s
      self.id
    end

    private

    def primitive_term_to_ruby(eterm)
      case eterm
      when Intruder::Atom
        atom_to_ruby(eterm)
      when Intruder::List, Intruder::Tuple
        eterm.to_a
      else
        eterm.to_s
      end
    end
    alias convert primitive_term_to_ruby 
    
    def atom_to_ruby(atom)
      string_value = atom.to_s
      case string_value
      when "true"
        true
      when "false"
        false
      else
        string_value.to_sym
      end
    end
  end
end
