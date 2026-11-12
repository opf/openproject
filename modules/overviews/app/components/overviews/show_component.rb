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

module Overviews
  class ShowComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include AngularHelper
    include Turbo::FramesHelper

    attr_reader :project, :current_user

    def initialize(project:, current_user:)
      super()

      @project = project
      @current_user = current_user
    end

    private

    def sidebar_enabled?
      life_cycle_sidebar_enabled? || custom_fields_sidebar_enabled?
    end

    def life_cycle_sidebar_enabled?
      @life_cycle_sidebar_enabled ||=
        current_user.allowed_in_project?(:view_project_phases, project) &&
        project.phases.active.any?
    end

    def custom_fields_sidebar_enabled?
      @custom_fields_sidebar_enabled ||=
        current_user.allowed_in_project?(:view_project_attributes, project) &&
          project.project_custom_fields
                 .visible
                 .group_by(&:project_custom_field_section)
                 .any? { |section, _| section.shown_in_overview_sidebar? }
    end

    def render_sidebar_turbo_frame(*ids, src: nil, target: nil, **attributes)
      turbo_frame_tag(*ids, src:, target:, **attributes) do
        render_skeleton
      end
    end

    def render_skeleton
      render(Primer::OpenProject::SidePanel.new(spacious: true)) do |panel|
        panel.with_section do |section|
          section.with_title(w: :full, classes: "SkeletonBox") { "" }

          flex_layout do |flex|
            3.times do
              flex.with_row(mb: 1) do
                render(Primer::Alpha::SkeletonBox.new(width: "100%", height: "21px"))
              end

              flex.with_row(mb: 3) do
                render(Primer::Alpha::SkeletonBox.new(width: "100%", height: "21px"))
              end
            end
          end
        end
      end
    end
  end
end
