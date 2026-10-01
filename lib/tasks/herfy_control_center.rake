# frozen_string_literal: true

require "net/http"
require "json"

namespace :herfy do
  namespace :control_center do
    desc "Create/update the 'Herfy Control Center' OIDC provider. Env: HERFY_CC_CLIENT_ID, HERFY_CC_CLIENT_SECRET, optional HERFY_CC_ISSUER (default https://controlcenter.herfy.com)"
    task setup: :environment do
      issuer = ENV.fetch("HERFY_CC_ISSUER", "https://controlcenter.herfy.com").chomp("/")
      provider = OpenIDConnect::Provider.find_or_initialize_by(slug: Herfy::ControlCenter::PROVIDER_SLUG)
      provider.display_name = "Herfy Control Center"
      provider.creator ||= User.system
      provider.oidc_provider = "custom"
      provider.metadata_url = "#{issuer}/.well-known/openid-configuration"
      provider.issuer = issuer
      provider.client_id = ENV.fetch("HERFY_CC_CLIENT_ID")
      provider.client_secret = ENV.fetch("HERFY_CC_CLIENT_SECRET")
      provider.scope = "openid profile email roles"
      provider.mapping_login = "email"
      provider.mapping_email = "email"
      provider.mapping_first_name = "given_name"
      provider.mapping_last_name = "family_name"
      provider.sync_groups = true
      provider.groups_claim = "groups"
      meta = JSON.parse(Net::HTTP.get(URI(provider.metadata_url)))
      %w[authorization_endpoint token_endpoint userinfo_endpoint jwks_uri].each { |k| provider.public_send(:"#{k}=", meta.fetch(k)) }
      provider.available = true
      provider.save!(validate: false)
      Herfy::ControlCenter.ensure_custom_fields!
      puts "Provider '#{provider.slug}' ready; login at /auth/#{provider.slug}"
    end

    desc "Pull users from Control Center: update fields, set manager/role, lock deactivated users. " \
         "Env: HERFY_CC_ISSUER, HERFY_CC_CLIENT_ID, HERFY_CC_CLIENT_SECRET, optional HERFY_CC_API_URL, HERFY_CC_CREATE_USERS=true"
    task sync: :environment do
      Herfy::ControlCenter::Sync.new.call
    end
  end
end
