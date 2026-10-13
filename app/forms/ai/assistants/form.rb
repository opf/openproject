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

module AI
  module Assistants
    class Form < ApplicationForm
      ICONS = %w[checklist pulse sparkle beaker briefcase people rocket book tools megaphone].freeze

      form do |f|
        f.fieldset_group(title: I18n.t("admin.ai_assistants.form.sections.general")) do |g|
          g.text_field(name: :name, label: AI::Assistant.human_attribute_name(:name), required: true,
                       caption: I18n.t("admin.ai_assistants.form.name_caption"), input_width: :large)

          g.text_area(name: :description, label: AI::Assistant.human_attribute_name(:description), rows: 3)

          g.select_list(name: :icon, label: AI::Assistant.human_attribute_name(:icon), input_width: :small,
                        include_blank: false) do |select|
            ICONS.each { |icon| select.option(value: icon, label: icon) }
          end

          g.check_box(name: :active, label: AI::Assistant.human_attribute_name(:active))
        end

        # The owner is chosen once. An admin creates a global assistant or one for a group.
        if @admin && model.new_record?
          f.fieldset_group(title: I18n.t("admin.ai_assistants.form.owner")) do |g|
            g.select_list(name: :principal_id, label: I18n.t("admin.ai_assistants.form.owner"), visually_hide_label: true,
                          input_width: :large, caption: I18n.t("admin.ai_assistants.form.owner_caption"),
                          include_blank: I18n.t("admin.ai_assistants.index.owners.global")) do |select|
              Group.order(:lastname).each { |group| select.option(value: group.id, label: group.name) }
            end
          end
        end

        f.fieldset_group(title: I18n.t("admin.ai_assistants.form.sections.instructions"),
                         description: I18n.t("admin.ai_assistants.form.instructions_caption")) do |g|
          g.text_area(name: :instructions, label: AI::Assistant.human_attribute_name(:instructions),
                      visually_hide_label: true, rows: 5)
        end

        # A personal assistant uses the default model; only an admin chooses one.
        if @admin
          f.fieldset_group(title: AI::Assistant.human_attribute_name(:model_id)) do |g|
            g.select_list(name: :model_id, label: AI::Assistant.human_attribute_name(:model_id), visually_hide_label: true,
                          input_width: :large, caption: I18n.t("admin.ai_assistants.form.model_caption"),
                          include_blank: I18n.t("admin.ai_assistants.form.model_default")) do |select|
              model_ids.each { |id| select.option(value: id, label: id) }
            end
          end
        end

        f.submit(name: :submit, label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
                 scheme: :primary)
      end

      def initialize(admin: false)
        super()
        @admin = admin
      end

      private

      # The current model stays selectable even when the connection no longer offers it.
      def model_ids
        ids = LlmConnection.active_connection.available_model_ids
        model.model_id.present? ? (ids | [model.model_id]) : ids
      end
    end
  end
end
