module OpenID
  class Consumer

    # A set of discovered services, for tracking which providers have
    # been attempted for an OpenID identifier
    class DiscoveredServices
      attr_reader :current

      def initialize(starting_url, yadis_url, services)
        @starting_url = starting_url
        @yadis_url = yadis_url
        @services = services.dup
        @current = nil
      end

      def next
        @current = @services.shift
      end

      def for_url?(url)
        [@starting_url, @yadis_url].member?(url)
      end

      def started?
        !@current.nil?
      end

      def empty?
        @services.empty?
      end
    end

    # Manages calling discovery and tracking which endpoints have
    # already been attempted.
    class DiscoveryManager
      def initialize(session, url, session_key_suffix=nil)
        @url = url

        @session = session
        @session_key_suffix = session_key_suffix || 'auth'
      end

      def get_next_service
        manager = get_manager
        if !manager.nil? && manager.empty?
          destroy_manager
          manager = nil
        end

        if manager.nil?
          yadis_url, services = yield @url
          manager = create_manager(yadis_url, services)
        end

        if !manager.nil?
          service = manager.next
          store(manager)
        else
          service = nil
        end

        return service
      end

      def cleanup(force=false)
        manager = get_manager(force)
        if !manager.nil?
          service = manager.current
          destroy_manager(force)
        else
          service = nil
        end
        return service
      end

      protected

      def get_manager(force=false)
        manager = load
        if force || manager.nil? || manager.for_url?(@url)
          return manager
        else
          return nil
        end
      end

      def create_manager(yadis_url, services)
        manager = get_manager
        if !manager.nil?
          raise StandardError, "There is already a manager for #{yadis_url}"
        end
        if services.empty?
          return nil
        end
        manager = DiscoveredServices.new(@url, yadis_url, services)
        store(manager)
        return manager
      end

      def destroy_manager(force=false)
        if !get_manager(force).nil?
          destroy!
        end
      end

      def session_key
        'OpenID::Consumer::DiscoveredServices::' + @session_key_suffix
      end

      def store(manager)
        @session[session_key] = manager
      end

      def load
        @session[session_key]
      end

      def destroy!
        @session[session_key] = nil
      end
    end
  end
end
