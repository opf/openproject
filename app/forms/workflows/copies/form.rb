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

class Workflows::Copies::Form < ApplicationForm
  def initialize(all_roles:, append_to: nil)
    super()
    @all_roles = all_roles
    @append_to = append_to
  end

  form do |copy|
    copy.group do |from_role|
      from_role.autocompleter(
        name: "target_role_ids",
        required: true,
        include_blank: false,
        label: helpers.t("workflows.copies.form.target_role_ids.label"),
        autocomplete_options: {
          multiple: true,
          decorated: true,
          closeOnSelect: false,
          appendTo: @append_to,
          data: {
            "test-selector": "target_roles_autocomplete"
          }
        }
      ) do |target_list|
        @all_roles.each do |role|
          target_list.option(label: role.name, value: role.id)
        end
      end
    end
  end
end
