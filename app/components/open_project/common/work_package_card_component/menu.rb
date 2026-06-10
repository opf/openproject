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

module OpenProject
  module Common
    class WorkPackageCardComponent
      class Menu < ApplicationComponent
        include OpPrimer::ComponentHelpers

        delegate :with_item, :with_avatar_item, :with_divider, :with_group, :with_sub_menu_item, to: :@menu

        attr_reader :work_package, :button_aria_label

        def initialize(work_package:, src: nil, button_aria_label: nil, **system_arguments)
          super()

          @work_package = work_package
          @button_aria_label = button_aria_label

          system_arguments[:menu_id] ||= dom_target(work_package, :menu)
          system_arguments[:src] = src
          system_arguments[:anchor_align] ||= :end
          system_arguments[:classes] = class_names(
            system_arguments[:classes],
            "op-work-package-card--menu",
            "hide-when-print"
          )
          @menu = Primer::Alpha::ActionMenu.new(**system_arguments)
        end

        private

        def before_render
          content
        end
      end
    end
  end
end
