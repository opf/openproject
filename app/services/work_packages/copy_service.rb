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

class WorkPackages::CopyService
  include ::Shared::ServiceContext
  include Contracted

  attr_accessor :user,
                :work_package,
                :contract_class

  def initialize(user:, work_package:, contract_class: WorkPackages::CreateContract)
    self.user = user
    self.work_package = work_package
    self.contract_class = contract_class
  end

  def call(send_notifications: true, **attributes)
    in_context(work_package, send_notifications) do
      copy(attributes, send_notifications)
    end
  end

  protected

  def copy(attribute_override, send_notifications)
    attributes = copied_attributes(work_package, attribute_override)

    copied = create(attributes, send_notifications)

    if copied.success?
      copy_watchers(copied.result)
    end

    copied.context = { copied_from: work_package }

    copied
  end

  def create(attributes, send_notifications)
    WorkPackages::CreateService
      .new(user: user,
           contract_class: contract_class)
      .call(attributes.merge(send_notifications: send_notifications).symbolize_keys)
  end

  def copied_attributes(wp, override)
    wp
      .attributes
      .slice(*writable_work_package_attributes(wp))
      .merge('parent_id' => wp.parent_id,
             'custom_field_values' => wp.custom_value_attributes)
      .merge(override)
  end

  def writable_work_package_attributes(wp)
    instantiate_contract(wp, user).writable_attributes
  end

  def copy_watchers(copied)
    work_package.watchers.each do |watcher|
      copied.add_watcher(watcher.user) if watcher.user.active?
    end
  end
end
