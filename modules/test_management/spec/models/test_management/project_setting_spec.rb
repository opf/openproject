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

  it "defaults folder tree layout to split_pane" do
    setting = described_class.for_project(project)
    expect(setting.effective_folder_tree_layout).to eq("split_pane")
    expect(setting.split_pane_layout?).to be(true)
  end

  it "persists sidebar layout" do
    setting = described_class.for_project(project)
    setting.folder_tree_layout = "sidebar"
    setting.save!

    reloaded = described_class.find(setting.id)
    expect(reloaded.effective_folder_tree_layout).to eq("sidebar")
    expect(reloaded.sidebar_layout?).to be(true)
    expect(described_class.folder_tree_layout_for(project)).to eq("sidebar")
  end

  it "rejects unknown layouts" do
    setting = described_class.for_project(project)
    setting.folder_tree_layout = "floating"
    expect(setting).not_to be_valid
    expect(setting.errors[:folder_tree_layout]).to be_present
  end

  describe ".enabled?" do
    it "is on by default and can be switched off" do
      expect(described_class.enabled?(project, :ci)).to be(true)

      setting = described_class.for_project(project)
      setting.enable_ci = false
      setting.save!

      expect(described_class.enabled?(project, :ci)).to be(false)
      expect(setting.enabled?(:ci)).to be(false)
    end
  end
end
