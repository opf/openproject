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

require "spec_helper"

RSpec.describe SquashTMIntegration::WorkPackageSquashTMTabComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:status) { :not_linked }
  let(:can_configure_server) { false }
  let(:can_manage_project_link) { false }
  let(:tab_state) do
    instance_double(SquashTMIntegration::WorkPackageTabState,
                    work_package:,
                    project:,
                    status:,
                    can_configure_server?: can_configure_server,
                    can_manage_project_link?: can_manage_project_link)
  end

  current_user { build_stubbed(:user) }

  subject(:render_component) { render_inline(described_class.new(tab_state)) }

  it "renders the empty state inside the tab turbo frame" do
    render_component

    expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
    expect(page).to have_text("No SquashTM requirement linked")
  end

  context "when the project is not linked to a SquashTM project" do
    let(:status) { :project_not_linked }

    it "asks the user to contact a project administrator" do
      render_component

      expect(page).to have_text("No SquashTM project linked")
      expect(page).to have_text("Please contact a project administrator")
      expect(page).to have_no_link("Link SquashTM project")
    end

    context "for a user allowed to manage the integration" do
      let(:can_manage_project_link) { true }

      it "links to the project settings, leaving the tab frame" do
        render_component

        expect(page).to have_css("a[data-turbo-frame='_top']", text: "Link SquashTM project")
      end
    end
  end

  context "without a configured server" do
    let(:status) { :no_server }

    it "asks the user to contact the instance administrator" do
      render_component

      expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
      expect(page).to have_text("SquashTM is not available")
      expect(page).to have_text("Please contact your instance administrator")
      expect(page).to have_no_link("Configure SquashTM")
    end

    context "for an administrator" do
      let(:can_configure_server) { true }

      it "links to the SquashTM administration, leaving the tab frame" do
        render_component

        expect(page).to have_no_text("Please contact your instance administrator")
        expect(page).to have_link("Configure SquashTM", href: "/squashtm_integration/admin/server")
        expect(page).to have_css("a[data-turbo-frame='_top']", text: "Configure SquashTM")
      end
    end
  end
end
