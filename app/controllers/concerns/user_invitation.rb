#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module UserInvitation
  module Events
    class << self
      def user_invited
        "user_invited"
      end

      def user_reinvited
        "user_reinvited"
      end
    end
  end

  module_function

  ##
  # Creates an invited user with the given email address.
  #
  # @param email E-Mail address the invitation is sent to.
  # @param login User's login (optional)
  # @param first_name The user's first name (optional)
  # @param last_name The user's last name (optional)
  #
  # @yield [user] Allows modifying the created user before saving it.
  #
  # @return The invited user. If the invitation failed, calling `#registered?`
  #         on the returned user will yield `false`. Check for validation errors
  #         in that case.
  def invite_new_user(email:, login: nil, first_name: nil, last_name: nil, send_notification: true)
    attributes = {
      mail: email,
      login:,
      firstname: first_name,
      lastname: last_name,
      status: Principal.statuses[:invited]
    }

    user = user_from_attributes(attributes)

    yield user if block_given?

    invite_user! user, send_notification:
  end

  ##
  # For the given user with at least the mail attribute set,
  # derives login and first name
  #
  # The default login is the email address.
  def user_from_attributes(attributes)
    ::Users::SetAttributesService
      .new(user: User.system, model: User.new, contract_class: ::Users::CreateContract)
      .call(attributes)
      .result
  end

  ##
  # Sends a new invitation to the user with a new token.
  #
  # @param user_id [Integer] ID of the user to be re-invited.
  # @return [Token] The new token used for the invitation.
  def reinvite_user(user_id)
    User.transaction do
      clear_tokens user_id
      reset_login user_id

      Token::Invitation.create!(user_id:).tap do |token|
        OpenProject::Notifications.send Events.user_reinvited, token
      end
    end
  end

  def clear_tokens(user_id)
    Token::Invitation.where(user_id:).delete_all
  end

  def reset_login(user_id)
    User.where(id: user_id).update_all identity_url: nil
    UserPassword.where(user_id:).destroy_all
  end

  ##
  # Invites the given user. An email will be sent to their email address
  # containing the token necessary for the user to register.
  #
  # Validates and saves the given user. The invitation will fail if the user is invalid.
  #
  # @return The invited user or nil if the invitation failed.
  def invite_user!(user, send_notification: true)
    user, token = user_invitation user

    if token && send_notification
      OpenProject::Notifications.send(Events.user_invited, token)

      user
    end
  end

  ##
  # Creates an invited user with the given email address.
  # If no first and last is given it will default to 'OpenProject User'
  # for the first name and 'To-be' for the last name.
  # The default login is the email address.
  #
  # @return Returns the user and the invitation token required to register.
  def user_invitation(user)
    User.transaction do
      user.invite

      if user.valid?
        token = Token::Invitation.create!(user:)
        user.save!

        [user, token]
      else
        [user, nil]
      end
    end
  end
end
