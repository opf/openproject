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
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:admin) }

  subject(:rendered) { render_inline(described_class.new(project:, user:)) }

  context "with the feature flag active", with_flag: { admin_privilege_elevation: true } do
    context "for an admin that is not elevated in the project" do
      it "shows that the project is seen with the membership permissions only", :aggregate_failures do
        rendered

        expect(page).to have_test_selector("admin-elevation-banner",
                                           text: I18n.t("admin_elevation.banner.not_elevated"))
        expect(page).to have_link(I18n.t("admin_elevation.banner.elevate"),
                                  href: %r{\A/projects/#{project.identifier}/admin_elevation/new})
      end
    end

    context "for an admin that is elevated in the project" do
      before { user.admin_elevation = Users::AdminElevation.in_projects([project.id]) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_test_selector("admin-elevation-banner")
      end
    end

    context "for a regular user" do
      let(:user) { build_stubbed(:user) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_test_selector("admin-elevation-banner")
      end
    end

    context "for a locked admin" do
      let(:user) { build_stubbed(:admin, status: :locked) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_test_selector("admin-elevation-banner")
      end
    end

    context "without a project" do
      let(:project) { nil }

      it "renders nothing" do
        rendered

        expect(page).to have_no_test_selector("admin-elevation-banner")
      end
    end

    context "with a project that is not yet saved" do
      let(:project) { build(:project) }

      it "renders nothing" do
        rendered

        expect(page).to have_no_test_selector("admin-elevation-banner")
      end
    end
  end

  context "with the feature flag inactive" do
    it "renders nothing" do
      rendered

      expect(page).to have_no_test_selector("admin-elevation-banner")
    end
  end
end
