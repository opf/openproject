module LobbyBoy
  module Configuration
    module HashInit
      def initialize(attr)
        attr.each do |name, value|
          instance_variable_set "@#{name}", value
        end
      end
    end

    class Client
      attr_reader :host, :cookie_domain,
                  :logged_in, :end_session_endpoint,
                  :refresh_offset, :refresh_interval,
                  :on_login_js_partial, :on_logout_js_partial

      include HashInit
    end

    class Provider
      attr_reader :name,
                  :client_id,
                  :issuer,
                  :end_session_endpoint,
                  :check_session_iframe

      include HashInit
    end

    def build_url(host, path)
      if path =~ /^https?:\/\//
        path
      else
        URI.join(host, path).to_s
      end
    end

    def host_name(host_address)
      URI.parse(host_address).host
    end

    def configure_client!(options)
      opts = options.dup

      opts[:end_session_endpoint] = build_url opts[:host], opts[:end_session_endpoint]
      opts[:cookie_domain] ||=
        if opts[:host].is_a? Symbol # e.g. :all to allow all domains
          opts[:host]
        else
          host_name opts[:host]
        end
      opts[:refresh_offset] ||= 120.seconds
      opts[:refresh_interval] ||= 30.seconds
      opts[:logged_in] ||= lambda { false }

      @client = Client.new opts
    end

    def configure_provider!(options)
      opts = options.dup

      opts[:end_session_endpoint] = build_url opts[:issuer], opts[:end_session_endpoint]
      opts[:check_session_iframe] = build_url opts[:issuer], opts[:check_session_iframe]

      @provider = Provider.new opts
    end

    def client
      @client
    end

    def provider
      @provider
    end

    def configured?
      client && provider
    end
  end
end
