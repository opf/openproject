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

module Backlogs
  class WorkPackageCardComponent < ApplicationComponent
    attr_reader :work_package, :menu_src

    delegate :with_menu, :with_metric, to: :card

    def initialize(work_package:, menu_src: nil, **system_arguments)
      super()

      @work_package = work_package
      @menu_src = menu_src
      @system_arguments = system_arguments
    end

    def call
      render(card) do |common_card|
        unless common_card.metric?
          common_card.with_metric do
            render(Backlogs::StoryPointsComponent.new(work_package:))
          end
        end
      end
    end

    private

    def card
      @card ||= OpenProject::Common::WorkPackageCardComponent.new(
        work_package:,
        menu_src:,
        show_assignee: true,
        show_priority: true,
        show_parent: true,
        status_scheme: :secondary,
        **@system_arguments
      )
    end

    def before_render
      content
    end
  end
end
