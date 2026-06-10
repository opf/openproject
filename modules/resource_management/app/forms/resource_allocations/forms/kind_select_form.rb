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

module ResourceAllocations
  module Forms
    class KindSelectForm < ApplicationForm
      def initialize(work_package:)
        super()

        @work_package = work_package
      end

      form do |f|
        f.hidden name: :work_package_id,
                 value: @work_package&.id,
                 scope_name_to_model: false

        f.advanced_radio_button_group(
          name: :allocation_kind,
          label: I18n.t("resource_management.allocate_resource_dialog.kind.label"),
          visually_hide_label: true,
          scope_name_to_model: false
        ) do |group|
          group.radio_button(
            value: "principal",
            checked: true,
            label: I18n.t("resource_management.allocate_resource_dialog.kind.principal.label"),
            caption: I18n.t("resource_management.allocate_resource_dialog.kind.principal.caption")
          )
          group.radio_button(
            value: "filter",
            label: I18n.t("resource_management.allocate_resource_dialog.kind.filter.label"),
            caption: I18n.t("resource_management.allocate_resource_dialog.kind.filter.caption")
          )
        end
      end
    end
  end
end
