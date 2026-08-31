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

# The variant screens answer at two addresses from one controller, and the guard that tells them
# apart has to sit between two other things. Both halves were got wrong once:
#
# - after ApplicationController#user_setup, or User.current is anonymous, Project.visible finds
#   nothing, and every project-scoped request redirects to the login page;
# - before any callback a controller adds itself, which read the type and variant it resolves.
#
# Neither is visible in a request spec: login_as stubs RequestStore[:current_user] — exactly what
# user_setup fills in — and a nil variant only surfaces as a render error deep in a component.
RSpec.describe "Variant configuration callback order" do # rubocop:disable RSpec/DescribeClass
  controllers = [
    WorkPackageTypes::DetailsTabController,
    WorkPackageTypes::DefaultsTabController,
    WorkPackageTypes::FormConfigurationTabController,
    WorkPackageTypes::FormConfigurationGroupsTabController,
    WorkPackageTypes::ProjectAttributesTabController,
    WorkPackageTypes::WorkflowTabController,
    WorkPackageTypes::PdfExportTemplateController,
    WorkPackageTypes::ExcludedElementsController,
    WorkPackageTypes::ConfigurationLinksController,
    WorkPackageTypes::ConfigurationIndependenceController,
    WorkPackageTypes::ConfigurationCopiesController,
    WorkPackageTypes::VariantsController,
    WorkPackageTypes::CreationWizardController,
    Workflows::MatrixController,
    Workflows::CopiesController,
    Workflows::Copies::FromVariantsController,
    Workflows::Copies::FromRolesController
  ]

  def before_filters(controller)
    controller._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)
  end

  controllers.each do |controller|
    describe controller.name do
      let(:filters) { before_filters(controller) }

      # Two shared tabs declared administration's layout of their own, which overrode the one the
      # scope resolves, so a project's page drew administration's menu. A rendering spec does not
      # judge chrome, so it is pinned here. Naming administration's layout is the regression; the
      # wizard's own no_menu and the matrix's frame-only false are both fine in either place.
      it "never fixes itself to administration's layout" do
        expect(controller._layout).not_to eq("admin")
      end

      it "decides who is asking only once the current user is known" do
        expect(filters.index(:require_admin)).to be > filters.index(:user_setup)
        expect(filters.index(:find_project_by_in_project_id)).to be > filters.index(:user_setup)
      end

      it "authorizes a project's request with the project it named" do
        expect(filters.index(:authorize)).to be > filters.index(:find_project_by_in_project_id)
      end

      # An administration-only screen answers before authorization on purpose: the permission map
      # does not define it for a project, so #authorize would raise instead of being reached.
      it "turns a project away from an administration-only screen before authorizing" do
        rejection = filters.index(:reject_administration_only_screen)

        expect(rejection).to be > filters.index(:user_setup)
        expect(rejection).to be < filters.index(:authorize)
      end

      # Everything else the controller adds of its own reads what these resolve.
      it "runs its own callbacks only after the scope is resolved" do
        guard = filters.index(:authorize)
        inherited = before_filters(ApplicationController) +
                    %i[reject_administration_only_screen require_admin find_project_by_in_project_id
                       authorize require_type_variants_feature]

        (filters - inherited).each do |filter|
          next unless filters.index(filter) # symbols only; inline blocks have no name

          expect(filters.index(filter)).to be > guard,
                                           "expected #{filter} to run after the scope is resolved"
        end
      end
    end
  end
end
