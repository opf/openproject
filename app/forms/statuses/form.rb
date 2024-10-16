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

module Statuses
  class Form < ApplicationForm
    attr_reader :submit_label

    def initialize(submit_label: nil)
      super()

      @submit_label = submit_label || I18n.t(:button_save)
    end

    form do |statuses_form|
      statuses_form.text_field(
        label: attribute_name(:name),
        name: :name,
        required: true,
        input_width: :medium
      )

      statuses_form.text_field(
        label: attribute_name(:default_done_ratio),
        name: :default_done_ratio,
        caption: percent_complete_field_caption,
        required: true,
        type: :number,
        min: 0,
        max: 100,
        maxlength: 7,
        autocomplete: "off",
        input_width: :small
      )

      statuses_form.check_box(
        label: attribute_name(:is_closed),
        name: :is_closed
      )

      statuses_form.check_box(
        label: attribute_name(:is_default),
        name: :is_default,
        disabled: already_default_status?,
        caption: I18n.t("statuses.edit.status_default_text"),
        data: {
          "admin--statuses-target": "isDefaultCheckbox",
          action: "admin--statuses#updateReadonlyCheckboxDisabledState"
        }
      )

      statuses_form.check_box(
        label: attribute_name(:is_readonly),
        name: :is_readonly,
        disabled: readonly_disabled?,
        caption: I18n.t("statuses.edit.status_readonly_html").html_safe,
        data: {
          "admin--statuses-target": "isReadonlyCheckbox",
          restricted: readonly_work_packages_restricted?
        }
      )

      if readonly_work_packages_restricted?
        statuses_form.html_content do
          angular_component_tag "opce-enterprise-banner",
                                inputs: {
                                  collapsible: true,
                                  textMessage: t("text_wp_status_read_only_html"),
                                  moreInfoLink: OpenProject::Static::Links.links[:enterprise_docs][:status_read_only][:href]
                                }
        end
      end

      statuses_form.check_box(
        label: attribute_name(:excluded_from_totals),
        name: :excluded_from_totals,
        caption: I18n.t("statuses.edit.status_excluded_from_totals_text")
      )

      statuses_form.color_select_list(
        label: attribute_name(:color_id),
        name: :color_id,
        caption: I18n.t("statuses.edit.status_color_text")
      )

      statuses_form.submit(
        scheme: :primary,
        name: :submit,
        label: submit_label
      )
    end

    def status
      model
    end

    def percent_complete_field_caption
      I18n.t("statuses.edit.status_percent_complete_text",
             href: url_helpers.admin_settings_progress_tracking_path).html_safe
    end

    def already_default_status?
      status.is_default_was == true
    end

    def readonly_disabled?
      readonly_work_packages_restricted? || already_default_status?
    end

    def readonly_work_packages_restricted?
      !status.can_readonly?
    end
  end
end
