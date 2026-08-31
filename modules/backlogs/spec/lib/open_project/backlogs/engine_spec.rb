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

RSpec.describe OpenProject::Backlogs::Engine do
  describe ".settings" do
    it "keeps only the burn direction plugin setting" do
      expect(described_class.settings).to eq(
        default: {
          "points_burn_direction" => "up"
        },
        menu_item: :backlogs_settings
      )
    end
  end

  describe "project menu" do
    it "points the backlog entries at the canonical backlog route" do
      project = create(:project)
      menu_items = Redmine::MenuManager.items(:project_menu, project).root.children

      backlogs = menu_items.detect { |item| item.name == :backlogs }
      backlog = backlogs.children.detect { |item| item.name == :backlog }

      expect(backlogs.url(project)).to eq(controller: "/backlogs/backlog", action: :show)
      expect(backlog.url(project)).to eq(controller: "/backlogs/backlog", action: :show)
    end
  end

  describe "admin menu" do
    it "registers the Backlogs entry from the engine" do
      admin_backlogs = Redmine::MenuManager.items(:admin_menu).children.find { |item| item.name == :admin_backlogs }

      expect(admin_backlogs.url).to eq(controller: "/backlogs/settings", action: :show)
    end
  end
end
