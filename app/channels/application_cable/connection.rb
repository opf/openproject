# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user_id = request.session[:user_id]
      user    = User.find_by(id: user_id) if user_id
      reject_unauthorized_connection unless user&.active?
      user
    end
  end
end
