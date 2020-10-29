module ActionDispatch
  module Session
    module LegacySupport
      EnvWrapper = Struct.new(:env)

      def self.included(klass)
        [
          :get_session,
          :get_session_model,
          :write_session,
          :delete_session,
          :find_session
        ].each do |m|
          klass.send(:alias_method, "#{m}_rails5".to_sym, m)
          klass.send(:remove_method, m)
        end
      end

      def get_session(env, sid)
        request = EnvWrapper.new(env)
        get_session_rails5(request, sid)
      end

      def set_session(env, sid, session_data, options)
        request = EnvWrapper.new(env)
        write_session_rails5(request, sid, session_data, options)
      end

      def destroy_session(env, session_id, options)
        request = EnvWrapper.new(env)
        if sid = current_session_id(request.env)
          get_session_model(request, sid).destroy
          request.env[self.class::SESSION_RECORD_KEY] = nil
        end
        generate_sid unless options[:drop]
      end

      def get_session_model(request, sid)
        if request.env[self.class::ENV_SESSION_OPTIONS_KEY][:id].nil?
          request.env[self.class::SESSION_RECORD_KEY] = find_session(sid)
        else
          request.env[self.class::SESSION_RECORD_KEY] ||= find_session(sid)
        end
      end

      def find_session(id)
        self.class.session_class.find_by_session_id(id) || self.class.session_class.new(:session_id => id, :data => {})
      end
    end
  end
end
