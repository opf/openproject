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

class Queries::WorkPackages::Selects::PropertySelect < Queries::WorkPackages::Selects::WorkPackageSelect
  def caption
    WorkPackage.human_attribute_name(name)
  end

  class_attribute :property_selects

  self.property_selects = {
    id: {
      sortable: -> {
        if Setting::WorkPackageIdentifier.semantic?
          ["#{Project.table_name}.identifier", "#{WorkPackage.table_name}.sequence_number"]
        else
          "#{WorkPackage.table_name}.id"
        end
      },
      groupable: false
    },
    project: {
      association: "project",
      sortable: "name",
      groupable: "#{WorkPackage.table_name}.project_id"
    },
    subject: {
      sortable: "#{WorkPackage.table_name}.subject"
    },
    type: {
      association: "type",
      sortable: "position",
      groupable: "#{WorkPackage.table_name}.type_id"
    },
    parent: {
      association: "ancestors_relations",
      sortable: false
    },
    status: {
      association: "status",
      sortable: "position",
      highlightable: true,
      groupable: "#{WorkPackage.table_name}.status_id"
    },
    priority: {
      association: "priority",
      sortable: "position",
      default_order: "desc",
      highlightable: true,
      groupable: "#{WorkPackage.table_name}.priority_id"
    },
    author: {
      association: "author",
      sortable: %w(lastname firstname id),
      groupable: "#{WorkPackage.table_name}.author_id"
    },
    assigned_to: {
      association: "assigned_to",
      sortable: %w(lastname firstname id),
      groupable: "#{WorkPackage.table_name}.assigned_to_id"
    },
    responsible: {
      association: "responsible",
      sortable: %w(lastname firstname id),
      groupable: "#{WorkPackage.table_name}.responsible_id"
    },
    updated_at: {
      sortable: "#{WorkPackage.table_name}.updated_at",
      default_order: "desc"
    },
    category: {
      association: "category",
      sortable: "name",
      groupable: "#{WorkPackage.table_name}.category_id"
    },
    version: {
      association: "version",
      sortable: "name",
      groupable: "#{WorkPackage.table_name}.version_id"
    },
    start_date: {
      sortable: "#{WorkPackage.table_name}.start_date"
    },
    due_date: {
      highlightable: true,
      sortable: "#{WorkPackage.table_name}.due_date"
    },
    estimated_hours: {
      sortable: "#{WorkPackage.table_name}.estimated_hours",
      summable: true
    },
    remaining_hours: {
      sortable: "#{WorkPackage.table_name}.remaining_hours",
      summable: true
    },
    spent_hours: {
      sortable: false,
      summable: false
    },
    done_ratio_for_weighted_average: {
      if: -> { WorkPackage.work_weighted_average_mode? },
      name: :done_ratio,
      sortable: "#{WorkPackage.table_name}.done_ratio",
      groupable: true,
      summable: true,
      summable_select: <<~SQL.squish,
        CASE
          WHEN estimated_hours IS NULL OR remaining_hours IS NULL OR estimated_hours <= 0 THEN NULL
          WHEN remaining_hours <= 0 THEN 100
          WHEN remaining_hours <= estimated_hours * 0.01 THEN 99
          WHEN remaining_hours >= estimated_hours THEN 0
          WHEN remaining_hours >= estimated_hours * 0.99 THEN 1
          ELSE ROUND( ((1 - (remaining_hours / estimated_hours)) * 100)::numeric )::integer
        END as done_ratio
      SQL
      summable_work_packages_select: false
    },
    done_ratio_for_simple_average: {
      if: -> { WorkPackage.simple_average_mode? },
      name: :done_ratio,
      sortable: "#{WorkPackage.table_name}.done_ratio",
      groupable: true,
      summable: true,
      summable_select: <<~SQL.squish,
        CASE
          WHEN done_ratio_count = 0 THEN NULL
          WHEN done_ratio >= done_ratio_count * 100 THEN 100
          WHEN done_ratio >= done_ratio_count * 99 THEN 99
          WHEN done_ratio <= 0 THEN 0
          WHEN done_ratio <= done_ratio_count THEN 1
          ELSE ROUND(done_ratio::numeric / done_ratio_count)::integer
        END as done_ratio
      SQL
      summable_work_packages_count_select: true
    },
    created_at: {
      sortable: "#{WorkPackage.table_name}.created_at",
      default_order: "desc"
    },
    duration: {
      sortable: "#{WorkPackage.table_name}.duration"
    },
    shared_with_users: {
      sortable: false,
      groupable: false
    }
  }

  def self.instances(_context = nil)
    active_selects = property_selects.reject do |_, options|
      condition = options[:if]
      condition && !condition.call
    end
    active_selects.filter_map do |default_name, options|
      name = options[:name] || default_name
      new(name, options.without(:if, :name))
    end
  end
end
