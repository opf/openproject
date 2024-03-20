module ::TwoFactorAuthentication
  module WebauthnRelyingParty
    extend ActiveSupport::Concern

    protected

    def webauthn_relying_party
      @webauthn_relying_party ||= begin
        origin = "#{Setting.protocol}://#{Setting.host_name}"

        WebAuthn::RelyingParty.new(
          origin:,
          id: URI(origin).host,
          name: Setting.app_title
        )
      end
    end
  end
end
