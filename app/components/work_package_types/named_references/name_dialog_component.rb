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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module NamedReferences
    class NameDialogComponent < ApplicationComponent
      include Translatable
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(record:, model_class:, copy_from_id: nil, ask_copy_source: true, url: nil, creating: false)
        super()

        @record = record
        @model_class = model_class
        @copy_from_id = copy_from_id
        @creating = creating
        @form_arguments = { record:, model_class:, copy_from_id:, ask_copy_source:, url: }
      end

      private

      attr_reader :record, :model_class, :copy_from_id, :creating, :form_arguments

      def dialog_id = NameFormComponent.dialog_id(model_class)

      def form_id = NameFormComponent.form_id(model_class)

      def title
        return reference_translate("form.copy_title", name: copy_source.name) if copy_source
        return reference_translate("form.edit_title") if record.persisted? && !creating

        reference_translate("form.save_title")
      end

      def copy_source
        return @copy_source if defined?(@copy_source)

        @copy_source = copy_from_id.present? ? model_class.find_by(id: copy_from_id) : nil
      end

      def submit_label
        record.persisted? ? I18n.t(:button_save) : I18n.t(:button_create)
      end
    end
  end
end
