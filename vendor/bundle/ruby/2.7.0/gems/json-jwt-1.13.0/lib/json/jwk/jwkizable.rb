module JSON
  class JWK
    module JWKizable
      module RSA
        def to_jwk(ex_params = {})
          params = {
            kty: :RSA,
            e: Base64.urlsafe_encode64(e.to_s(2), padding: false),
            n: Base64.urlsafe_encode64(n.to_s(2), padding: false)
          }.merge ex_params
          if private?
            params.merge!(
              d: Base64.urlsafe_encode64(d.to_s(2), padding: false),
              p: Base64.urlsafe_encode64(p.to_s(2), padding: false),
              q: Base64.urlsafe_encode64(q.to_s(2), padding: false),
              dp: Base64.urlsafe_encode64(dmp1.to_s(2), padding: false),
              dq: Base64.urlsafe_encode64(dmq1.to_s(2), padding: false),
              qi: Base64.urlsafe_encode64(iqmp.to_s(2), padding: false),
            )
          end
          JWK.new params
        end
      end

      module EC
        def to_jwk(ex_params = {})
          params = {
            kty: :EC,
            crv: curve_name,
            x: Base64.urlsafe_encode64([coordinates[:x]].pack('H*'), padding: false),
            y: Base64.urlsafe_encode64([coordinates[:y]].pack('H*'), padding: false)
          }.merge ex_params
          params[:d] = Base64.urlsafe_encode64([coordinates[:d]].pack('H*'), padding: false) if private_key?
          JWK.new params
        end

        private

        def curve_name
          case group.curve_name
          when 'prime256v1'
            :'P-256'
          when 'secp384r1'
            :'P-384'
          when 'secp521r1'
            :'P-521'
          when 'secp256k1'
            :secp256k1
          else
            raise UnknownAlgorithm.new('Unknown EC Curve')
          end
        end

        def coordinates
          unless @coordinates
            hex = public_key.to_bn.to_s(16)
            data_len = hex.length - 2
            hex_x = hex[2, data_len / 2]
            hex_y = hex[2 + data_len / 2, data_len / 2]
            @coordinates = {
              x: hex_x,
              y: hex_y
            }
            @coordinates[:d] = private_key.to_s(16) if private_key?
          end
          @coordinates
        end
      end
    end
  end
end

OpenSSL::PKey::RSA.send :include, JSON::JWK::JWKizable::RSA
OpenSSL::PKey::EC.send :include, JSON::JWK::JWKizable::EC
