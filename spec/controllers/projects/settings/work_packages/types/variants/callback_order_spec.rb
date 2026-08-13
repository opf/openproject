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

# ProjectScoped resolves the project and authorizes inside the inherited #find_type rather than
# in a before_action of its own, because the lookups have to sit between two other things and
# only that position does. This pins both halves, since each was got wrong once:
#
# - after ApplicationController#user_setup, or User.current is anonymous, Project.visible finds
#   nothing, and every request redirects to the login page;
# - before any callback a tab controller adds itself, which read @type and @variant.
#
# Neither is visible in a request spec: login_as stubs RequestStore[:current_user] — exactly
# what user_setup fills in — and a nil @variant only shows up as a render error deep in a
# component.
RSpec.describe "Project-scoped variant controllers' callback order" do # rubocop:disable RSpec/DescribeClass
  scoped = Projects::Settings::WorkPackages::Types::Variants

  tab_controllers = [
    scoped::DetailsTabController,
    scoped::DefaultsTabController,
    scoped::FormConfigurationTabController,
    scoped::FormConfigurationGroupsTabController,
    scoped::ProjectAttributesTabController,
    scoped::WorkflowTabController,
    scoped::PdfExportTemplateController,
    scoped::ExcludedElementsController
  ]

  def before_filters(controller)
    controller._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)
  end

  (tab_controllers + [scoped::CreationWizardController, scoped::MatrixController]).each do |controller|
    describe controller.name do
      let(:filters) { before_filters(controller) }

      it "no longer requires an instance administrator" do
        expect(filters).not_to include(:require_admin)
      end
    end
  end

  tab_controllers.each do |controller|
    describe controller.name do
      let(:filters) { before_filters(controller) }

      it "looks the type up only once the current user is known" do
        expect(filters.index(:find_type)).to be > filters.index(:user_setup)
      end

      it "looks the variant up after the type" do
        expect(filters.index(:find_variant)).to be > filters.index(:find_type)
      end

      # The callbacks a tab adds of its own read @type and @variant, so every one of them has
      # to follow both lookups. DetailsTabController's set_editable is the one that caught this.
      it "runs its own callbacks only after both lookups" do
        own = filters - before_filters(WorkPackageTypes::BaseTabController) - %i[find_type find_variant]
        last_lookup = filters.index(:find_variant)

        own.each do |filter|
          next unless filters.index(filter) # symbols only; inline blocks have no name

          expect(filters.index(filter)).to be > last_lookup,
                                           "expected #{filter} to run after the type and variant are resolved"
        end
      end
    end
  end

  describe scoped::CreationWizardController do
    let(:filters) { before_filters(described_class) }

    it "decides the step only once the variant is known" do
      expect(filters.index(:set_current_step)).to be > filters.index(:find_variant)
    end
  end
end
