module Humpty
  class Server
    class ConfigurationException < Error; end

    include HTTParty
    attr_reader :id

    def initialize(id)
      @id = id
      self.class.base_uri "#{configuration["alice"]["base_url"]}:#{configuration["alice"]["port"]}"
    end

    def queues
      requested_attributes = %w(name durable auto_delete messages_ready messages_unacknowledged messages_uncommitted messages acks_uncommitted consumers transactions memory)
      get("/queues/root/#{requested_attributes.join('/')}")["queues"]
    end

    def bindings
      get("/bindings")["bindings"]
    end

    def control
      get("/control")
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
      get("/exchanges")["exchanges"]
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
    [:get, :post].each do |verb|
      eval <<-EVAL
      def #{verb}(url, opts = {})
        self.class.#{verb}(url, opts)
      end
      EVAL
    end
  end
end
