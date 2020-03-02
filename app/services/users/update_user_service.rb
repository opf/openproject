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

module Users
  class UpdateUserService
    include Contracted

    attr_accessor :current_user, :user

    def initialize(current_user:, user:)
      self.current_user = current_user
      self.user = user
      self.contract_class = Users::UpdateContract
    end

    def call(attributes: {})
      User.execute_as current_user do
        set_attributes(attributes)

        success, errors = validate_and_save(user, current_user)
        ServiceResult.new(success: success, errors: errors, result: user)
      end
    end

    private

    def set_attributes(attributes)
      user.attributes = attributes
    end
  end
end
