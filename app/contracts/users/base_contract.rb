#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Users
  class BaseContract < ::ModelContract
    attribute :login
    attribute :firstname
    attribute :lastname
    attribute :name
    attribute :mail
    attribute :admin,
              writeable: ->(*) { user.admin? && model.id != user.id }
    attribute :language

    attribute :auth_source_id,
              writeable: ->(*) { user.allowed_to_globally?(:manage_user) }

    attribute :identity_url,
              writeable: ->(*) { user.admin? }

    attribute :force_password_change,
              writeable: ->(*) { user.admin? }

    def self.model
      User
    end

    validate :password_writable
    validate :existing_auth_source

    private

    ##
    # User#password is not an ActiveModel property,
    # but just an accessor, so we need to identify it being written there.
    # It is only present when freshly written
    def password_writable
      # Only admins or the user themselves can set the password
      return if user.admin? || user.id == model.id

      errors.add :password, :error_readonly if model.password.present?
    end

    def existing_auth_source
      if auth_source_id && AuthSource.find_by_unique(auth_source_id).nil?
        errors.add :auth_source, :error_not_found
      end
    end
  end
end
