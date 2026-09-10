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

module Forums
  class Form < ApplicationForm
    form do |f|
      f.text_field(
        name: :name,
        label: attribute_name(:name),
        required: true,
        input_width: :large,
        autocomplete: "off"
      )

      f.text_area(
        name: :description,
        label: attribute_name(:description),
        required: true,
        input_width: :large,
        rows: 5
      )

      f.group(layout: :horizontal) do |button_group|
        button_group.button(
          name: :cancel,
          label: I18n.t(:button_cancel),
          tag: :a,
          href: cancel_href
        )

        button_group.submit(
          name: :submit,
          label: submit_label,
          scheme: :primary
        )
      end
    end

    def initialize(project:, submit_label: I18n.t(:button_save))
      super()
      @project = project
      @submit_label = submit_label
    end

    private

    attr_reader :submit_label, :project

    def cancel_href
      url_helpers.project_forums_path(project)
    end
  end
end
