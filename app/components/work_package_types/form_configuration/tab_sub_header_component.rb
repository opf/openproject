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
  module FormConfiguration
    class TabSubHeaderComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:)
        super()

        @variant = variant
      end

      private

      attr_reader :variant

      def kind = WorkPackageTypes::NamedReferences::Kind::FORM

      def candidates = ::FormConfiguration.in_display_order.to_a

      def offers_new? = variant.project_id.nil?

      def button_label = t("forms.button")

      def configure_dialog_path = url_helpers.configure_dialog_type_form_configuration_path(**variant.path_args)
    end
  end
end
