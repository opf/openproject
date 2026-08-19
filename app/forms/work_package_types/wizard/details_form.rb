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
    #
    # The parent is chosen before the wizard starts and only the variant name is
    # editable here. The core settings are inherited from the parent (see Type),
    # so they are shown read-only to explain where their values come from.
    class DetailsForm < ApplicationForm
      form do |details_form|
        details_form.hidden(name: :parent_id)

        details_form.text_field(
          name: :name,
          label: label(:name),
          input_width: :large,
          required: true,
          autocomplete: "off",
          validation_message: validation_message_for(:name)
        )

        details_form.color_select_list(
          name: :color_id,
          label: label(:color),
          input_width: :large,
          required: true,
          disabled: true,
          caption: inherited_caption
        )

        details_form.check_box(
          name: :is_milestone,
          label: label(:is_milestone),
          disabled: true,
          caption: inherited_caption
        )

        details_form.check_box(
          name: :is_in_roadmap,
          label: label(:is_in_roadmap),
          disabled: true,
          caption: inherited_caption
        )
      end

      private

      def label(attribute)
        Type.human_attribute_name(attribute)
      end

      def inherited_caption
        helpers.t("types.creation_wizard.fields.inherited_from_parent_html", parent: model.parent&.name)
      end

      def validation_message_for(attribute)
        model.errors.messages_for(attribute).to_sentence.presence
      end
    end
  end
end
