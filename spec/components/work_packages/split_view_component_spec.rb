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

RSpec.describe WorkPackages::SplitViewComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  let(:project)      { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  subject do
    with_controller_class(NotificationsController) do
      with_request_url("/notifications/details/:work_package_id") do
        render_inline(described_class.new(id: work_package.id, base_route: notifications_path))
      end
    end
  end

  before do
    allow(WorkPackage).to receive(:visible).and_return(WorkPackage.where(id: work_package.id))
  end

  it "renders successfully" do
    subject

    expect(page).to have_text("Overview")
    expect(page).to have_test_selector("wp-details-tab-component--tabs")
    expect(page).to have_test_selector("wp-details-tab-component--close")
    expect(page).to have_test_selector("wp-details-tab-component--full-screen")
  end
end
