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

class WorkPackages::DeleteService < BaseServices::Delete
  include ::WorkPackages::Shared::UpdateAncestors

  private

  def persist(service_result)
    descendants = model.descendants.to_a

    result = super

    if result.success?
      update_ancestors_all_attributes(result.all_results).each do |ancestor_result|
        result.merge!(ancestor_result)
      end

      destroy_descendants(descendants, result)
      delete_associated(model)
    end

    result
  end

  def destroy(work_package)
    work_package.destroy
  rescue ActiveRecord::StaleObjectError
    destroy(work_package.reload)
  end

  def destroy_descendants(descendants, result)
    descendants.each do |descendant|
      result.add_dependent!(ServiceResult.new(success: destroy(descendant), result: descendant))
    end
  end

  def delete_associated(model)
    delete_notifications_resource(model.id)
  end

  def delete_notifications_resource(id)
    Notification
      .where(resource_type: :WorkPackage, resource_id: id)
      .delete_all
  end
end
