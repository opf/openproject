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
  module ConfigurationLinks
    class ConfirmDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "configuration-link-confirm-dialog"

      def initialize(variant:, aspect:, source:)
        super()

        @variant = variant
        @aspect = aspect
        @source = source
      end

      private

      attr_reader :variant, :aspect, :source

      def changing_source?
        variant.linked?(aspect)
      end

      def title
        if changing_source?
          t("types.edit.reuse_mode.inherited.confirm_dialog.change_source.title")
        else
          t("types.edit.reuse_mode.inherited.confirm_dialog.from_manual.title")
        end
      end

      def heading
        if changing_source?
          t("types.edit.reuse_mode.inherited.confirm_dialog.change_source.heading")
        else
          t("types.edit.reuse_mode.inherited.confirm_dialog.from_manual.heading")
        end
      end

      def switch_path
        type_configuration_link_switch_path(**variant.path_args, aspect:)
      end
    end
  end
end
