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

require "rails_helper"

RSpec.describe AdminElevationSessions::BannerComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:subproject) { create(:project, parent: project) }
  shared_let(:admin) { create(:admin) }

  let(:user) { admin }
  let(:banner_project) { project }
  let(:elevation_sessions) { AdminElevationSession.where(user: admin) }

  subject(:rendered) do
    render_inline(described_class.new(project: banner_project, user:, elevation_sessions:))
  end

  context "with the feature flag active", with_flag: { admin_privilege_elevation: true } do
    context "for an admin that is not elevated in the project" do
      it "shows that the project is seen with the membership permissions only", :aggregate_failures do
        rendered

        expect(page).to have_test_selector("admin-elevation-banner",
                                           text: I18n.t("admin_elevation.banner.not_elevated"))
        expect(page).to have_link(I18n.t("admin_elevation.banner.elevate"),
                                  href: %r{\A/projects/#{project.identifier}/admin_elevation/new})
        expect(page).to have_no_test_selector("admin-elevation-banner-elevated")
      end
    end

    context "for an admin that is elevated in the project" do
      let!(:elevation_session) { create(:admin_elevation_session, user: admin, project:) }

      before { user.admin_elevation = Users::AdminElevation.in_projects([project.id]) }

      after { user.admin_elevation = nil }

      it "shows the elevation with its expiry as a relative time", :aggregate_failures do
        rendered

        expect(page).to have_css("[data-test-selector='admin-elevation-banner-elevated'] " \
                                 "relative-time[tense='future'][datetime='#{elevation_session.expires_at.iso8601}']")
        expect(page).to have_no_test_selector("admin-elevation-banner")
      end

      it "offers to end the elevation after a confirmation" do
        rendered

        expect(page).to have_link(I18n.t("admin_elevation.banner.end"),
                                  href: "/projects/#{project.identifier}/admin_elevation") do |link|
          link["data-turbo-method"] == "delete" &&
            link["data-turbo-confirm"] == I18n.t("admin_elevation.banner.end_confirmation")
        end
      end
    end

    context "for an admin that is elevated in the parent project including subprojects" do
      let(:banner_project) { subproject }

      before do
        create(:admin_elevation_session, user: admin, project:, include_subprojects: true)
        user.admin_elevation = Users::AdminElevation.in_projects([project.id, subproject.id])
      end

      after { user.admin_elevation = nil }

      it "shows the elevation in the subproject" do
        rendered

        expect(page).to have_test_selector("admin-elevation-banner-elevated")
      end
    end

    context "for an admin that is elevated in another project only" do
      before do
        create(:admin_elevation_session, user: admin, project: create(:project))
      end

      it "shows that the project is seen with the membership permissions only" do
        rendered

        expect(page).to have_test_selector("admin-elevation-banner")
      end
    end

    context "for a regular user" do
      let(:user) { build_stubbed(:user) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_css("[data-test-selector^='admin-elevation-banner']")
      end
    end

    context "for a locked admin" do
      let(:user) { build_stubbed(:admin, status: :locked) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_css("[data-test-selector^='admin-elevation-banner']")
      end
    end

    context "without a project" do
      let(:banner_project) { nil }

      it "renders nothing" do
        rendered

        expect(page).to have_no_css("[data-test-selector^='admin-elevation-banner']")
      end
    end

    context "with a project that is not yet saved" do
      let(:banner_project) { build(:project) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_css("[data-test-selector^='admin-elevation-banner']")
      end
    end
  end

  context "with the feature flag inactive" do
    it "renders nothing" do
      rendered

      expect(page).to have_no_css("[data-test-selector^='admin-elevation-banner']")
    end
  end
end
