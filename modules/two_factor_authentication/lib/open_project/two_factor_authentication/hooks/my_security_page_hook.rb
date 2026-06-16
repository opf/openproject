# frozen_string_literal: true

module OpenProject::TwoFactorAuthentication
  module Hooks
    class MySecurityPageHook < ::OpenProject::Hook::ViewListener
      def view_my_security_2fa_section(context = {})
        context[:hook_caller].render(
          ::TwoFactorAuthentication::My::SecuritySectionComponent.new(
            user: context[:user],
            cookies: context[:cookies]
          )
        )
      end
    end
  end
end
