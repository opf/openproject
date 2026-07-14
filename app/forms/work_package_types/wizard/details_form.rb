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

module WorkPackageTypes
  module Wizard
    # Fields for the wizard's Details step. Intentionally submit-button free: the
    # wizard footer drives submission (see FooterComponent).
    class DetailsForm < ApplicationForm
      form do |details_form|
        details_form.select_list(
          name: :parent_id,
          input_width: :medium,
          label: I18n.t("types.creation_wizard.fields.parent"),
          caption: I18n.t("types.edit.settings.parent_type_text"),
          required: true,
          validation_message: validation_message_for(:parent)
        ) do |parent_types|
          available_parents.each do |type|
            parent_types.option(value: type.id, label: type.name, selected: type.id == model.parent_id)
          end
        end

        details_form.text_field(
          name: :name,
          label: I18n.t("types.creation_wizard.fields.variant_label"),
          required: true,
          validation_message: validation_message_for(:name)
        )

        details_form.rich_text_area(
          name: :description,
          label: Type.human_attribute_name(:description),
          rich_text_options: { showAttachments: false }
        )
      end

      private

      def available_parents
        Type.roots.where.not(id: model.id)
      end

      def validation_message_for(attribute)
        model.errors.messages_for(attribute).to_sentence.presence
      end
    end
  end
end
