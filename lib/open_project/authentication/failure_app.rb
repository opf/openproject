module OpenProject
  module Authentication
    class FailureApp
      def call(env)
        warden = env['warden']

        if warden.present? && warden.result == :failure
          wrong_credentials warden.message, headers: warden.headers
        else
          unauthorized
        end
      end

      def wrong_credentials(message, headers: {})
        [401, headers, [message]]
      end

      def unauthorized
        [401, {}, []]
      end
    end
  end
end
