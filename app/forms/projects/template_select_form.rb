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

module Projects
  class TemplateSelectForm < ApplicationForm
    extend Dry::Initializer[undefined: false]
    include OpenProject::TextFormatting

    BLANK_VALUE = ""
    private_constant :BLANK_VALUE

    option :template_id
    option :parent_id, optional: true
    option :workspace_type
    option :current_user, default: -> { User.current }

    delegate :strip_tags, to: :@view_context

    form do |f|
      f.advanced_radio_button_group(
        name: :template_id,
        label: I18n.t("create_project.template_label"),
        visually_hide_label: true,
        scope_name_to_model: false,
        data: {
          test_selector: "use_template"
        }
      ) do |group|
        group.radio_button(
          value: BLANK_VALUE,
          label: blank_template_label,
          id: "template_id_blank",
          caption: blank_template_caption,
          checked: template_id.blank?
        )

        available_templates.each do |template|
          group.radio_button(
            value: template.id,
            label: template.name,
            caption: format_caption(template.description),
            checked: template.id == template_id
          )
        end
      end

      f.hidden(name: :parent_id, value: parent_id, scope_name_to_model: false) if parent_id
    end

    private

    def available_templates
      @available_templates ||= Project
                                 .available_templates(workspace_type)
                                 .order(name: :asc)
    end

    def format_caption(text)
      return I18n.t("create_project.blank_description") if text.blank?

      render(Primer::Beta::Text.new(classes: %w[line-clamp-3 lh-default])) do
        strip_tags(format_text(text))
      end
    end

    def blank_template_label
      return unless Project.workspace_types.key?(workspace_type)

      I18n.t("create_#{workspace_type}.blank_template.label")
    end

    def blank_template_caption
      return unless Project.workspace_types.key?(workspace_type)

      I18n.t("create_#{workspace_type}.blank_template.description")
    end
  end
end
