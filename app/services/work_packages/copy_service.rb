#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WorkPackages::CopyService
  include ::Shared::ServiceContext
  include Contracted
  include ::Copy::Concerns::CopyAttachments

  attr_accessor :user,
                :work_package,
                :contract_class

  def initialize(user:, work_package:, contract_class: WorkPackages::CreateContract)
    self.user = user
    self.work_package = work_package
    self.contract_class = contract_class
  end

  def call(send_notifications: nil, copy_attachments: true, **attributes)
    in_context(work_package, send_notifications:) do
      copy(attributes, copy_attachments, send_notifications)
    end
  end

  protected

  def copy(attribute_override, copy_attachments, send_notifications)
    copied = create(work_package,
                    attribute_override,
                    send_notifications)
      .on_success do |copy_call|
        remove_author_watcher(copy_call.result)
        copy_watchers(copy_call.result)
        copy_work_package_attachments(copy_call.result) if copy_attachments
      end

    copied.state.copied_from_work_package_id = work_package&.id

    copied
  end

  def create(work_package, attribute_overrides, send_notifications)
    WorkPackages::CreateService
      .new(user:,
           contract_class:)
      .call(**copied_attributes(work_package, attribute_overrides).merge(send_notifications:).symbolize_keys)
  end

  def copied_attributes(work_package, override)
    overwritten_attributes = override.stringify_keys

    attributes = work_package
                   .attributes
                   .slice(*writable_work_package_attributes(work_package))
                   .merge('parent_id' => work_package.parent_id,
                          'custom_field_values' => work_package.custom_value_attributes)
                   .merge(overwritten_attributes)

    if overwritten_attributes.has_key?('start_date') &&
      overwritten_attributes.has_key?('due_date') &&
      !overwritten_attributes.has_key?('duration')
      attributes.delete('duration')
    end

    attributes
  end

  def writable_work_package_attributes(work_package)
    instantiate_contract(work_package, user).writable_attributes
  end

  def remove_author_watcher(copied)
    copied.remove_watcher(copied.author)
  end

  def copy_watchers(copied)
    work_package.watcher_users.each do |user|
      copied.add_watcher(user) if user.active?
    end
  end

  def copy_work_package_attachments(copy)
    copy_attachments(
      'WorkPackage',
      from: work_package,
      to: copy,
      references: %i[description]
    )
  end
end
