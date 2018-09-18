#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class WorkPackages::CreateService
  include ::WorkPackages::Shared::UpdateAncestors
  include ::Shared::ServiceContext

  attr_accessor :user,
                :work_package,
                :contract_class

  def initialize(user:, contract_class: WorkPackages::CreateContract)
    self.user = user
    self.contract_class = contract_class
  end

  def call(attributes: {},
           work_package: WorkPackage.new,
           send_notifications: true)
    in_context(send_notifications) do
      create(attributes, work_package)
    end
  end

  protected

  def create(attributes, work_package)
    result = set_attributes(attributes, work_package)

    result.success = if result.success
                       work_package.attachments = work_package.attachments_replacements if work_package.attachments_replacements
                       work_package.save
                     else
                       false
                     end

    if result.success?
      result.merge!(reschedule_related(work_package))

      update_ancestors_all_attributes(result.all_results).each do |ancestor_result|
        result.merge!(ancestor_result)
      end
    else
      result.success = false
    end

    result
  end

  def set_attributes(attributes, wp)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: wp,
           contract_class: contract_class)
      .call(attributes)
  end

  def reschedule_related(work_package)
    result = WorkPackages::SetScheduleService
             .new(user: user,
                  work_package: work_package)
             .call

    result.self_and_dependent.each do |r|
      if !r.result.save
        result.success = false
        r.errors = r.result.errors
      end
    end

    result
  end
end
