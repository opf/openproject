module OpenProject
  module Authentication
    module SessionExpiry
      def session_ttl_enabled?
        Setting.session_ttl_enabled? && Setting.session_ttl.to_i >= 5
      end

      def session_ttl_minutes
        Setting.session_ttl.to_i.minutes
      end

      def session_ttl_expired?
        # Only when the TTL setting exists
        return false unless session_ttl_enabled?

        # If the session is rack-provided and empty, also skip it
        return false if session.empty?

        session[:updated_at].nil? || (session[:updated_at] + session_ttl_minutes) < Time.now
      end
    end
  end
end
