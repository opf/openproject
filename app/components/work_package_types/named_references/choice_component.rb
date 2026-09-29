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
  module NamedReferences
    class ChoiceComponent < ApplicationComponent
      include Translatable
      include OpPrimer::ComponentHelpers

      def initialize(variant:, model_class:, back_url: nil)
        super(variant)

        @model_class = model_class
        @back_url = back_url
      end

      private

      attr_reader :model_class, :back_url

      def variant = model

      def options = offers_new? ? [existing_option, new_option] : [existing_option]

      def offers_new? = model_class.project_owned? || variant.project_id.nil?

      def group_data
        { controller: "mode-switch-radio", action: "change->mode-switch-radio#select" }
      end

      def existing_option
        {
          value: "existing",
          checked: reuses_existing?,
          label: reference_translate("wizard.choice.existing.label"),
          caption: reference_translate("wizard.choice.existing.caption"),
          nested_content: panel,
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": dialog_path(:change_dialog),
            test_selector: "#{dom_class(model_class)}-choice-existing"
          }
        }
      end

      def new_option
        {
          value: "new",
          checked: !reuses_existing?,
          label: reference_translate("wizard.choice.new.label"),
          caption: reference_translate("wizard.choice.new.caption"),
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": dialog_path(:start_dialog),
            test_selector: "#{dom_class(model_class)}-choice-new"
          }
        }
      end

      def panel
        return unless reuses_existing?
        return if candidates.empty?

        PanelComponent.new(variant:, model_class:, candidates:, selected: record_id, back_url:)
      end

      def reuses_existing? = !offers_new? || record_id != started_id

      def record_id = variant.public_send(:"#{model_class.model_name.singular}_id")

      def started_id = helpers.params[:"started_#{model_class.model_name.singular}_id"].presence&.to_i

      def candidates
        @candidates ||= begin
          scope = model_class.available_in(variant.project).in_display_order
          scope = scope.where.not(id: record_id) unless reuses_existing?
          scope.to_a
        end
      end

      def dialog_path(action)
        url_helpers.public_send(:"#{action}_type_#{model_class.model_name.singular}_path",
                                **variant.path_args.merge(back_url:).compact)
      end
    end
  end
end
