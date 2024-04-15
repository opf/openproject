##
# This is a fix for a new SMTP bug introduced with Ruby 3.
# This can be removed once the official fix from the `mail` gem maintainers
# has been released and the gem bumped by us.
#
# Details: https://community.openproject.org/projects/openproject/work_packages/42385/activity
module OpenProject
  module Patches
    module MailSmtpStartTlsAutoHotfix
      def build_smtp_session
        super.tap do |smtp|
          smtp.disable_starttls if disable_starttls?
        end
      end

      def disable_starttls?
        settings[:enable_starttls_auto] == false && !settings[:enable_starttls]
      end
    end
  end
end

require "mail"

Mail::SMTP.prepend OpenProject::Patches::MailSmtpStartTlsAutoHotfix
