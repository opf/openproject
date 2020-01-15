#-- encoding: UTF-8

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

require 'users/base_contract'

module Users
  class CreateContract < BaseContract
    attribute :status do
      unless model.active? || model.invited?
        # New users may only have these two statuses
        errors.add :status, :invalid_on_create
      end
    end

    validate :user_allowed_to_add
    validate :authentication_defined

    private

    def authentication_defined
      errors.add :password, :blank if model.active? && no_auth?
    end

    def no_auth?
      model.password.blank? && model.auth_source_id.blank? && model.identity_url.blank?
    end

    ##
    # Users can only be created by Admins
    def user_allowed_to_add
      unless user.admin?
        errors.add :base, :error_unauthorized
      end
    end
  end
end
