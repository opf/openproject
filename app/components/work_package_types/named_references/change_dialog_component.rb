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
    class ChangeDialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def self.dialog_id(model_class) = "change-#{ActionView::RecordIdentifier.dom_class(model_class)}-dialog"

      def self.form_id(model_class) = "change-#{ActionView::RecordIdentifier.dom_class(model_class)}-form"

      def initialize(variant:, model_class:, back_url: nil)
        super()

        @variant = variant
        @model_class = model_class
        @back_url = back_url
      end

      private

      attr_reader :variant, :model_class, :back_url

      def dialog_id = self.class.dialog_id(model_class)

      def form_id = self.class.form_id(model_class)

      def title = model_class.reference_t("change.title")

      def form_arguments
        {
          id: form_id,
          url: url_helpers.public_send(:"change_type_#{model_class.reference_association}_path",
                                       **variant.path_args.merge(back_url:).compact),
          method: :patch,
          data: { turbo: false }
        }
      end
    end
  end
end
