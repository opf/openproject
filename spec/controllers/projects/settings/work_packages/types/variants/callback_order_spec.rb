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

require "spec_helper"

# Pinned here rather than in a request spec on purpose. These controllers authorize against
# the current user and look the project up through Project.visible, both of which need
# ApplicationController's user_setup to have run. When authorization was prepended it ran
# first, User.current was still anonymous, and every request redirected to the login page —
# yet every request spec passed, because login_as sets User.current directly and so hides
# the missing user_setup entirely. Only a real browser session showed the bug.
RSpec.describe "Project-scoped variant controllers' callback order" do # rubocop:disable RSpec/DescribeClass
  controllers = [
    Projects::Settings::WorkPackages::Types::Variants::DetailsTabController,
    Projects::Settings::WorkPackages::Types::Variants::DefaultsTabController,
    Projects::Settings::WorkPackages::Types::Variants::WorkflowTabController,
    Projects::Settings::WorkPackages::Types::Variants::ProjectAttributesTabController,
    Projects::Settings::WorkPackages::Types::Variants::FormConfigurationTabController,
    Projects::Settings::WorkPackages::Types::Variants::FormConfigurationGroupsTabController,
    Projects::Settings::WorkPackages::Types::Variants::PdfExportTemplateController,
    Projects::Settings::WorkPackages::Types::Variants::CreationWizardController,
    Projects::Settings::WorkPackages::Types::Variants::MatrixController
  ]

  def before_filters(controller)
    controller._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)
  end

  controllers.each do |controller|
    describe controller.name do
      let(:filters) { before_filters(controller) }

      it "establishes the current user before authorizing" do
        expect(filters.index(:authorize)).to be > filters.index(:user_setup)
      end

      it "establishes the current user before looking the project up" do
        expect(filters.index(:find_project_by_project_id)).to be > filters.index(:user_setup)
      end

      it "authorizes before looking the type up" do
        next if filters.exclude?(:find_type)

        expect(filters.index(:find_type)).to be > filters.index(:authorize)
      end

      it "no longer requires an instance administrator" do
        expect(filters).not_to include(:require_admin)
      end
    end
  end
end
