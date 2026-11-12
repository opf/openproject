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
require Rails.root.join("modules/backlogs/db/migrate/20261110120000_enable_boards_for_backlogs_projects")

RSpec.describe EnableBoardsForBacklogsProjects, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  describe "projects" do
    let!(:with_backlogs_only) { create(:project, enabled_module_names: %w[work_package_tracking backlogs]) }
    let!(:with_both) { create(:project, enabled_module_names: %w[work_package_tracking backlogs board_view]) }
    let!(:without_backlogs) { create(:project, enabled_module_names: %w[work_package_tracking]) }

    it "enables boards wherever backlogs is enabled" do
      migrate

      expect(with_backlogs_only.reload).to be_module_enabled("board_view")
      expect(without_backlogs.reload).not_to be_module_enabled("board_view")
    end

    it "does not duplicate an already enabled boards module" do
      migrate

      expect(with_both.reload.enabled_modules.where(name: "board_view").count).to eq(1)
    end
  end

  describe "the default modules for new projects" do
    before do
      Setting.find_by(name: "default_projects_modules")&.destroy
      Setting.clear_cache
    end

    context "when the setting lists backlogs without boards" do
      before { Setting.default_projects_modules = %w[work_package_tracking backlogs] }

      it "appends boards while preserving the other modules" do
        migrate
        Setting.clear_cache

        expect(Setting.default_projects_modules).to eq(%w[work_package_tracking backlogs board_view])
      end
    end

    context "when the setting already lists both" do
      before { Setting.default_projects_modules = %w[work_package_tracking backlogs board_view] }

      it "leaves the setting untouched" do
        migrate
        Setting.clear_cache

        expect(Setting.default_projects_modules.count("board_view")).to eq(1)
      end
    end

    context "when the setting does not list backlogs" do
      before { Setting.default_projects_modules = %w[work_package_tracking news] }

      it "leaves the setting untouched" do
        migrate
        Setting.clear_cache

        expect(Setting.default_projects_modules).to eq(%w[work_package_tracking news])
      end
    end

    context "when the setting is not stored in the database" do
      it "does not create it" do
        migrate

        expect(Setting.find_by(name: "default_projects_modules")).to be_nil
      end
    end
  end
end
