# frozen_string_literal: true

#-- copyright
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
#++

class Queries::WorkPackages::Filter::LabelsFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def available? = OpenProject::FeatureDecisions.work_package_labels_active?

  def self.key = :label_id
  def human_name = WorkPackage.human_attribute_name("labels")
  def ar_object_filter? = true
  def type = :list_optional

  def allowed_values
    @allowed_values ||= Label.pluck(:id, :name).map { |id, name| [name, id.to_s] }
  end

  def where # rubocop:disable Metrics/AbcSize
    case operator
    when "="
      "#{WorkPackage.table_name}.id IN (#{work_package_labelings.where(label_id: values).to_sql})"
    when "!"
      "#{WorkPackage.table_name}.id NOT IN (#{work_package_labelings.where(label_id: values).to_sql})"
    when "*"
      "#{WorkPackage.table_name}.id IN (#{work_package_labelings.to_sql})"
    when "!*"
      "#{WorkPackage.table_name}.id NOT IN (#{work_package_labelings.to_sql})"
    end
  end

  def value_objects
    available_labels = Label.where(id: values).index_by(&:id)

    values.filter_map { |id| available_labels[id.to_i] }
  end

  private

  def work_package_labelings
    Labeling.where(labelable_type: WorkPackage.to_s).select(:labelable_id)
  end
end
