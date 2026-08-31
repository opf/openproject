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

class My::Notifications::ProjectAutocompleterForm < ApplicationForm
  def initialize(readonly: false, user: nil)
    super()
    @readonly = readonly
    @excluded_project_ids = if !readonly && user
                              user.notification_settings.where.not(project: nil).pluck(:project_id).map(&:to_s)
                            else
                              []
                            end
  end

  form do |f|
    filters = [{ name: "active", operator: "=", values: ["t"] }]
    filters << { name: "id", operator: "!", values: @excluded_project_ids } if @excluded_project_ids.any?

    f.project_autocompleter(
      name: :project_id,
      label: Project.model_name.human,
      required: true,
      autocomplete_options: {
        data: { test_selector: "my-notifications-project-autocompleter" },
        appendTo: "##{My::Notifications::ProjectSettingsDialogComponent::DIALOG_ID}",
        readonly: @readonly,
        filters:
      }
    )
  end
end
