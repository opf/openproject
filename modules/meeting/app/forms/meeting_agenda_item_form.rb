#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class MeetingAgendaItemForm < ApplicationForm
  form do |agenda_item_form|
    agenda_item_form.select_list(
      name: :work_package_id,
      label: "Work package",
      include_blank: true,
      # disabled: @preselected_work_package.present? # does not work, work_package_id is nil when form gets submitted
    ) do |wp_select_list|
      WorkPackage.visible
        .order(:id)
        .map { |wp| [wp.subject, wp.id] }
        .each do |subject, id|
          wp_select_list.option(
            label: "##{id} #{subject}",
            value: id
          )
        end
    end
    agenda_item_form.text_field(
      name: :title,
      label: "Title",
      required: true
    )
    agenda_item_form.text_area(
      name: :input,
      label: "Input",
    )
    unless @preselected_work_package.present?
      agenda_item_form.text_area(
        name: :output,
        label: "Output",
      )
      agenda_item_form.text_field(
        name: :duration_in_minutes,
        label: "Duration in minutes",
        type: :number
      )
    end
    
    agenda_item_form.submit(name: "Save", label: "Save", scheme: :primary)
  end

  def initialize(preselected_work_package: nil)
    @preselected_work_package = preselected_work_package
  end
end