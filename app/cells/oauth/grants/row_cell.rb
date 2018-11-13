module OAuth
  module Grants
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::OAuthHelper

      def grant
        model
      end

      def application
        grant.application
      end

      def application_name
        application.name
      end

      def created_at
        grant.created_at
      end

      def scopes
        oauth_scope_translations(application)
      end

      def revoke_link
        link_to(
          I18n.t('oauth.grants.revoke'),
          revoke_my_oauth_grant_path(grant.id),
          method: 'POST',
          class: "oauth-grants--revoke-link icon icon-delete"
        )
      end

      def button_links
        [
          revoke_link
        ]
      end
    end
  end
end
