#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module UserInvitation
  module Events
    class << self
      def user_invited
        'user_invited'
      end

      def user_reinvited
        'user_reinvited'
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
  def invite_new_user(email:, login: nil, first_name: nil, last_name: nil)
    user = User.new mail: email,
                    login: login,
                    firstname: first_name,
                    lastname: last_name,
                    status: Principal::STATUSES[:invited]

    assign_user_attributes(user)

    yield user if block_given?

    invite_user! user
  end

  ##
  # For the given user with at least the mail attribute set,
  # derives login and first name
  #
  # The default login is the email address.
  def assign_user_attributes(user)
    placeholder = placeholder_name(user.mail)

    user.login = user.login.presence || user.mail
    user.firstname = user.firstname.presence || placeholder.first
    user.lastname = user.lastname.presence || placeholder.last
    user.language = user.language.presence || Setting.default_language
  end

  ##
  # Sends a new invitation to the user with a new token.
  #
  # @param user_id [Integer] ID of the user to be re-invited.
  # @return [Token] The new token used for the invitation.
  def reinvite_user(user_id)
    clear_tokens user_id

    Token::Invitation.create!(user_id: user_id).tap do |token|
      OpenProject::Notifications.send Events.user_reinvited, token
    end
  end

  def clear_tokens(user_id)
    Token::Invitation.where(user_id: user_id).delete_all
  end

  ##
  # Creates a placeholder name for the user based on their email address.
  # For the unlikely case that the local or domain part of the email address
  # are longer than 30 characters they will be trimmed to 27 characters and an
  # elipsis will be appended.
  def placeholder_name(email)
    first, last = email.split('@').map { |name| trim_name(name) }

    [first, '@' + last]
  end

  def trim_name(name)
    if name.size > 30
      name[0..26] + '...'
    else
      name
    end
  end

  ##
  # Invites the given user. An email will be sent to their email address
  # containing the token necessary for the user to register.
  #
  # Validates and saves the given user. The invitation will fail if the user is invalid.
  #
  # @return The invited user or nil if the invitation failed.
  def invite_user!(user)
    user, token = user_invitation user

    if token
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
        token = Token::Invitation.create! user: user
        user.save!

        return [user, token]
      end
    end

    [user, nil]
  end
end
