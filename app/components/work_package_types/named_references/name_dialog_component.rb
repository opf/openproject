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
    class NameDialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(record:, kind:, copy_from_id: nil, ask_copy_source: true, url: nil)
        super()

        @record = record
        @kind = kind
        @form_arguments = { record:, kind:, copy_from_id:, ask_copy_source:, url: }
      end

      private

      attr_reader :record, :kind, :form_arguments

      def dialog_id = NameFormComponent.dialog_id(kind)

      def form_id = NameFormComponent.form_id(kind)

      def title
        record.persisted? ? kind.t("form.edit_title") : kind.t("form.new_title")
      end

      def submit_label
        record.persisted? ? I18n.t(:button_save) : I18n.t(:button_create)
      end
    end
  end
end
