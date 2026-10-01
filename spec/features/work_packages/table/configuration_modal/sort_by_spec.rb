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

RSpec.describe "Work Package table configuration modal sort-by spec", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let!(:work_package) { create(:work_package, project:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it "does not offer internal, non-displayable columns as sort options (COMMS-930)" do
    modal.open_and_switch_to("Sort by")

    option_texts = page.all("#modal-sorting select.form--select option").map(&:text)

    expect(option_texts).not_to include("Autocomplete")
    expect(option_texts).not_to include("Exact match")
    expect(option_texts).to include("Status")
  end
end
