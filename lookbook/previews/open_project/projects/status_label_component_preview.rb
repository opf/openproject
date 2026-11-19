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

module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class StatusLabelComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param status [Symbol] select [on_track, at_risk, off_track, not_started, finished, discontinued]
    # @param with_icon [boolean]
    def playground(with_icon: false, status: :on_track)
      project = FactoryBot.build_stubbed(:project, status_code: status, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    def with_icon(with_icon: true, status: :on_track)
      project = FactoryBot.build_stubbed(:project, status_code: status, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @!group Status

    # @param with_icon [boolean]
    def on_track(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :on_track, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @param with_icon [boolean]
    def at_risk(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :at_risk, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @param with_icon [boolean]
    def off_track(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :off_track, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @param with_icon [boolean]
    def not_started(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :not_started, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @param with_icon [boolean]
    def finished(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :finished, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @param with_icon [boolean]
    def discontinued(with_icon: true)
      project = FactoryBot.build_stubbed(:project, status_code: :discontinued, status_explanation: "some explanation")

      render(Projects::StatusLabelComponent.new(project:, with_icon:))
    end

    # @!endgroup
  end
end
