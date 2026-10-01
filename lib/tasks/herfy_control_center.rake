# frozen_string_literal: true

require "net/http"
require "json"

namespace :herfy do
  namespace :control_center do
    desc "Create/update the Herfy Control Center OIDC provider from HERFY_CC_* env (see lib/herfy/control_center/provisioner.rb)"
    task setup: :environment do
      abort "Set HERFY_CC_ISSUER, HERFY_CC_CLIENT_ID and HERFY_CC_CLIENT_SECRET" unless Herfy::ControlCenter::Provisioner.configured?
      provider = Herfy::ControlCenter::Provisioner.call
      puts "Provider '#{provider.slug}' ready; login at /auth/#{provider.slug}"
    end

    desc "Pull users from Control Center (HERFY_CC_* env; HERFY_CC_API_URL overrides the base URL, HERFY_CC_CREATE_USERS=true pre-creates accounts)"
    task sync: :environment do
      Herfy::ControlCenter::Sync.new.call
    end
  end
end
