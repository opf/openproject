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

class Queries::SetAttributesService < BaseServices::SetAttributes
  def set_attributes(params)
    set_ordered_work_packages params.delete(:ordered_work_packages)
    super
  end

  def set_default_attributes(_params)
    if model.include_subprojects.nil?
      model.include_subprojects = Setting.display_subprojects_work_packages?
    end

    set_default_user
  end

  def set_default_user
    model.change_by_system do
      model.user = user
    end
  end

  def set_ordered_work_packages(ordered_hash)
    return if ordered_hash.nil? || model.persisted?

    available = WorkPackage.where(id: ordered_hash.keys.map(&:to_s)).pluck(:id).to_set

    ordered_hash.each do |key, position|
      # input keys are symbols due to hashie::mash, and AR doesn't like that
      wp_id = key.to_s.to_i
      next unless available.include?(wp_id)

      model.ordered_work_packages.build(work_package_id: wp_id, position:)
    end
  end
end
