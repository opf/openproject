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

module FullCalendar
  class ResourceAllocationEvent < Event
    attr_accessor :scheduled_entry, :visible

    class << self
      # A scheduled entry is one allocation's share of a single day, so an allocation
      # spanning several days becomes one event per day, grouped by the allocation.
      def from_scheduled_entry(scheduled_entry, visible:)
        allocation = scheduled_entry.allocation
        date = scheduled_entry.allocated_on

        event = new(
          id: "#{allocation.id}-#{date.iso8601}",
          group_id: allocation.id,
          starts_at: date,
          ends_at: date,
          all_day: true,
          title: visible ? title_for(scheduled_entry.work_package) : hidden_label
        )
        event.scheduled_entry = scheduled_entry
        event.visible = visible

        event
      end

      private

      def title_for(work_package)
        "#{work_package.project.name}: #{work_package.formatted_id} #{work_package.subject}"
      end

      def hidden_label
        I18n.t("resource_management.my_work.hidden_work_package")
      end
    end

    def additional_attributes
      {
        allocationId: scheduled_entry.allocation.id,
        hours: (scheduled_entry.minutes / 60.0).round(2)
      }.merge(visible ? work_package_attributes : {})
    end

    private

    def work_package_attributes
      work_package = scheduled_entry.work_package

      {
        typeId: work_package.type_id,
        workPackageId: work_package.to_param,
        workPackageFormattedId: work_package.formatted_id,
        workPackageSubject: work_package.subject,
        projectId: work_package.project.id,
        projectIdentifier: work_package.project.identifier,
        projectName: work_package.project.name
      }
    end
  end
end
