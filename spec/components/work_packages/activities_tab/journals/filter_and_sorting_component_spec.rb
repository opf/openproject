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

RSpec.describe WorkPackages::ActivitiesTab::Journals::FilterAndSortingComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking meetings]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:hide_meetings_item) { "[data-test-selector='op-wp-journals-filter-hide-meetings']" }

  subject { render_inline(described_class.new(work_package:)) }

  before { allow(User).to receive(:current).and_return(user) }

  context "when the user may view meetings in a project" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings] }) }

    it "offers the hide-meetings filter" do
      subject

      expect(page).to have_css(hide_meetings_item, visible: :all)
    end
  end

  context "when the user cannot view meetings anywhere" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "does not offer the hide-meetings filter, but keeps the other filters" do
      subject

      expect(page).to have_no_css(hide_meetings_item, visible: :all)
    end
  end
end
