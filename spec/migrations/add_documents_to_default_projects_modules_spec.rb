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
require Rails.root.join("db/migrate/20260106151226_add_documents_to_default_projects_modules")

RSpec.describe AddDocumentsToDefaultProjectsModules, type: :model do
  let(:base_modules) { %w[calendar board_view work_package_tracking gantt news costs wiki] }

  before do
    # Ensure a clean state
    Setting.find_by(name: "default_projects_modules")&.destroy
    Setting.clear_cache
  end

  context "when real_time_text_collaboration is enabled",
          with_settings: { real_time_text_collaboration_enabled: true } do
    context "when default_projects_modules setting exists in DB" do
      before do
        Setting.default_projects_modules = base_modules
      end

      it "adds documents to the default modules" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        Setting.clear_cache
        expect(Setting.default_projects_modules).to include("documents")
      end

      it "preserves existing modules" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        Setting.clear_cache
        expect(Setting.default_projects_modules).to include(*base_modules)
      end

      context "when documents is already in the default modules" do
        before do
          Setting.default_projects_modules = base_modules + ["documents"]
        end

        it "does not duplicate documents" do
          ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

          Setting.clear_cache
          expect(Setting.default_projects_modules.count("documents")).to eq(1)
        end
      end
    end

    context "when default_projects_modules setting does not exist in DB" do
      it "does not create the setting (seeder handles new installations)" do
        expect(Setting.find_by(name: "default_projects_modules")).to be_nil

        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        # Setting should still not exist - seeder will handle it
        expect(Setting.find_by(name: "default_projects_modules")).to be_nil
      end
    end
  end

  context "when real_time_text_collaboration is disabled",
          with_settings: { real_time_text_collaboration_enabled: false } do
    before do
      Setting.default_projects_modules = base_modules
    end

    it "does not modify the default modules" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      Setting.clear_cache
      expect(Setting.default_projects_modules).not_to include("documents")
      expect(Setting.default_projects_modules).to match_array(base_modules)
    end
  end

  context "when real_time_text_collaboration_enabled setting does not exist" do
    before do
      Setting.default_projects_modules = base_modules
      allow(Setting).to receive(:exists?).and_call_original
      allow(Setting).to receive(:exists?).with(:real_time_text_collaboration_enabled).and_return(false)
    end

    it "does not modify the default modules" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      Setting.clear_cache
      expect(Setting.default_projects_modules).not_to include("documents")
      expect(Setting.default_projects_modules).to match_array(base_modules)
    end
  end
end
