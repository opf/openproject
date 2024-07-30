# -- copyright
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
# ++

class Shares::CreateOrUpdateService
  def initialize(user:, create_contract_class:, update_contract_class:, contract_options: {})
    self.user = user
    self.create_contract_class = create_contract_class
    self.update_contract_class = update_contract_class
    self.contract_options = contract_options
  end

  def call(entity:, user_id:, **)
    actual_service(entity, user_id).call(entity:, user_id:, **)
  end

  private

  attr_accessor :user, :create_contract_class, :update_contract_class, :contract_options

  def actual_service(entity, user_id)
    if (member = Member.find_by(entity:, principal: user_id))
      Shares::UpdateService.new(user:, model: member, contract_class: update_contract_class, contract_options:)
    else
      Shares::CreateService.new(user:, contract_class: create_contract_class, contract_options:)
    end
  end
end
