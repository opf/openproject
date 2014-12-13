module API
  module Helpers
    def current_user
      return User.current if Rails.env.test?
      user_id = env['rack.session']['user_id']
      User.current = user_id ? User.find(user_id) : User.anonymous
    end

    def authenticate
      raise API::Errors::Unauthenticated if current_user.nil? || current_user.anonymous? if Setting.login_required?
    end

    def authorize(permission, context: nil, global: false, user: current_user, allow: true)
      is_authorized = AuthorizationService.new(permission, context: context, global: global, user: user).call
      raise API::Errors::Unauthorized unless is_authorized && allow
      is_authorized
    end
  end
end
