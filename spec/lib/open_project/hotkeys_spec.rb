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

RSpec.describe OpenProject::Hotkeys do
  let(:project) { build(:project) }

  describe ".for_modules_menu_item" do
    it "always maps My page" do
      expect(described_class.for_modules_menu_item(:my_page, project)).to eq("g m")
    end

    it "does not map the global fallbacks inside a project" do
      expect(described_class.for_modules_menu_item(:work_packages, project)).to be_nil
    end

    it "maps the global fallbacks outside a project" do
      expect(described_class.for_modules_menu_item(:work_packages, nil)).to eq("g w p")
      expect(described_class.for_modules_menu_item(:wikis, nil)).to eq("g w i")
    end

    it "returns nil for unknown names" do
      expect(described_class.for_modules_menu_item(:unknown, nil)).to be_nil
    end
  end

  describe ".for_project_menu_item" do
    it "maps known project menu items" do
      expect(described_class.for_project_menu_item(:overview)).to eq("g o")
      expect(described_class.for_project_menu_item(:calendar_view)).to eq("g c")
    end

    it "returns nil for unknown names" do
      expect(described_class.for_project_menu_item(:unknown)).to be_nil
    end
  end

  describe ".for_action" do
    it "returns the action hotkey" do
      expect(described_class.for_action(:shortcuts_help)).to eq("?,Shift+?")
    end
  end

  describe ".for_wiki" do
    it "returns the wiki hotkey" do
      expect(described_class.for_wiki).to eq("g w i")
    end
  end
end
