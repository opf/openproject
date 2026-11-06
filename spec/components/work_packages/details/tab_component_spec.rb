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

require "rails_helper"

RSpec.describe WorkPackages::Details::TabComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  let(:work_package) { create(:work_package, project:) }

  before { work_package } # realize before render so after_create registration runs

  subject do
    with_controller_class(NotificationsController) do
      with_request_url("/notifications/details/:work_package_id") do
        render_inline(described_class.new(work_package:, base_route: notifications_path))
      end
    end
  end

  describe "full-screen link" do
    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "MYPROJ") }

      it "uses the semantic displayId in the href" do
        subject

        expect(work_package.display_id).to eq("MYPROJ-1")
        full_screen = page.find("[data-test-selector='wp-details-tab-component--full-screen']")
        expect(full_screen[:href]).to include("/work_packages/MYPROJ-1")
        expect(full_screen[:href]).not_to include("/work_packages/#{work_package.id}/")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      let(:project) { create(:project, identifier: "myproj") }

      it "uses the numeric id in the href" do
        subject

        expect(work_package.display_id).to eq(work_package.id)
        full_screen = page.find("[data-test-selector='wp-details-tab-component--full-screen']")
        expect(full_screen[:href]).to include("/work_packages/#{work_package.id}/")
      end
    end
  end
end
