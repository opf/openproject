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

RSpec.describe TestManagement::ProjectSetting do
  let(:project) { create(:project) }

  it "defaults folder tree layout to split_pane and accepts sidebar" do
    setting = described_class.for_project(project)
    expect(setting.effective_folder_tree_layout).to eq("split_pane")
    expect(setting.split_pane_layout?).to be(true)

    setting.folder_tree_layout = "sidebar"
    expect(setting).to be_valid
    expect(setting.effective_folder_tree_layout).to eq("sidebar")
  end

  it "rejects unknown layouts" do
    setting = described_class.for_project(project)
    setting.folder_tree_layout = "grid"
    expect(setting).not_to be_valid
    expect(setting.errors[:folder_tree_layout]).to be_present
  end

  it "rejects a display prefix longer than the column" do
    setting = described_class.for_project(project)
    setting.display_prefix = "x" * (described_class::DISPLAY_PREFIX_MAX_LENGTH + 1)
    expect(setting).not_to be_valid
    expect(setting.errors[:display_prefix]).to be_present
  end
end
