module OpenIDConnect
  class UserSessionLink < ::ApplicationRecord
    self.table_name = "oidc_user_session_links"

    belongs_to :session, class_name: "Sessions::UserSession", dependent: :delete
  end
end
