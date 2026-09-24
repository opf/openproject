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
  module ConfigurationDependents
    class DialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      DIALOG_ID = "configuration-dependents-dialog"

      def initialize(variant:, aspect:)
        super()

        @variant = variant
        @aspect = aspect
      end

      private

      attr_reader :variant, :aspect

      def dependents
        @dependents ||= variant.dependents_for(aspect).preload(:type)
      end

      def dependent_path(dependent) = helpers.aspect_edit_path(dependent, aspect)

      def dependent_link(dependent, bold_font: false)
        render(Primer::Beta::Link.new(href: dependent_path(dependent),
                                      font_weight: (bold_font ? :bold : :normal),
                                      data: { turbo_frame: "_top" })) do
          dependent.display_name
        end
      end

      def relation(dependent)
        t("types.edit.reuse_mode.dependents.dialog.variant_of_html",
          type_name: content_tag(:b, dependent.type.name))
      end
    end
  end
end
