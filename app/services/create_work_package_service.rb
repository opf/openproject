#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'work_packages/create_contract'

class CreateWorkPackageService
  include Concerns::Contracted

  self.contract = WorkPackages::CreateContract

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call(work_package, send_notifications: true)
    User.execute_as user do
      JournalManager.with_send_notifications send_notifications do
        create(work_package)
      end
    end
  end

  private

  def create(work_package)
    initialize_contract(work_package)
    assign_defaults(work_package)

    result, errors = validate_and_save(work_package)

    ServiceResult.new(success: result,
                      errors: errors,
                      result: work_package)
  end

  def assign_defaults(work_package)
    work_package.author ||= user
  end

  def initialize_contract(work_package)
    self.contract = self.class.contract.new(work_package, user)
  end
end
