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

RSpec.describe WorkPackages::ActivitiesTab::LazyIndexComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:paginator) { instance_double(Pagy::Offset, page: 1, pages: 1) }

  current_user { user }

  before do
    render_inline(
      described_class.new(
        work_package:,
        journals: work_package.journals,
        paginator:,
        last_server_timestamp: Time.current.iso8601
      )
    )
  end

  it "does not render the comment input without comment permission" do
    expect(page).to have_no_test_selector("op-work-package-journal--new-comment-component")
  end

  context "with comment permission" do
    let(:permissions) { %i[view_work_packages add_work_package_comments] }

    it "renders the comment input" do
      expect(page).to have_test_selector("op-work-package-journal--new-comment-component")
    end
  end
end
