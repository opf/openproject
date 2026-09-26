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
  module ReuseMode
    # The radios never submit - Selecting the other option is intercepted by the
    # stimulus controller, which opens the selection/confirmation dialog flow.
    # The real state changes only when the surrounding frame reloads after a successful switch.
    class ModeSelectorForm < ApplicationForm
      def initialize(inherited:, manual:, group_data:)
        super()

        @inherited = inherited
        @manual = manual
        @group_data = group_data
      end

      form do |mode_form|
        mode_form.advanced_radio_button_group(name: :mode, data: @group_data) do |group|
          group.radio_button(**@inherited)
          group.radio_button(**@manual)
        end
      end
    end
  end
end
