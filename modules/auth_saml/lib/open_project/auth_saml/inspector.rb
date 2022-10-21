module OpenProject
  module AuthSaml
    module Inspector
      module_function

      def inspect_response(auth_hash)
        response = auth_hash.dig(:extra, :response_object)
        if response
          code = response.status_code ? "(CODE #{response.status_code})" : nil
          message = response.status_message ? "(MESSAGE #{response.status_code})" : nil
          yield "SAML response success ?  #{response.success?} #{code} #{message}"

          errors = Array(response.errors).map(&:to_s).join(", ")
          yield "SAML errors: #{errors}" if errors.present?

          yield "SAML response XML: #{response.response || '(not present)'}"
        end
        uid = auth_hash[:uid]
        yield "SAML response uid (name identifier): #{uid || '(not present)'}"

        info = auth_hash[:info]
        yield "SAML retrieved attributes: #{info.inspect}"

        yield "SAML auth hash is invalid, attributes are missing." unless auth_hash.valid?

        session_idx = auth_hash.dig(:extra, :session_index)
        yield "SAML session index: #{session_idx}"
      end
    end
  end
end
