# frozen_string_literal: true

class Mngt::StreamUsersController < ApplicationController
  before_action :require_login
  no_authorization_required! :index

  def index
    users = User.active.where.not(id: current_user.id).order(:firstname, :lastname).limit(200)

    unless Mngt::Companies.can_see_all?(current_user.mail)
      domain = current_user.mail.to_s.split("@").last.downcase
      users = users.where("mail ILIKE ?", "%@#{domain}")
    end

    avatar_ids = Attachment.where(description: "avatar", container_type: "Principal")
                           .where(container_id: users.pluck(:id)).pluck(:container_id).to_set

    render json: users.map { |u|
      entry = { id: "op_#{u.id}", name: u.name }
      entry[:avatarUrl] = "/users/#{u.id}/avatar" if avatar_ids.include?(u.id)
      entry
    }
  end
end
