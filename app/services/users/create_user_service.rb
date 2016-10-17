#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'work_packages/create_contract'

module Users
  class CreateUserService
    include Concerns::Contracted

    self.contract = Users::CreateContract

    attr_reader :current_user

    def initialize(current_user:)
      @current_user = current_user
    end

    def call(new_user)
      User.execute_as current_user do
        create(new_user)
      end
    end

    private

    def create(new_user)
      initialize_contract(new_user)

      result, errors = validate_and_save(new_user)

      ServiceResult.new(success: result,
                        errors: errors,
                        result: new_user)
    end

    def initialize_contract(new_user)
      self.contract = self.class.contract.new(new_user, current_user)
    end
  end
end
