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
require Rails.root.join("modules/backlogs/db/migrate/20260313164539_migrate_versions_to_sprints")
require Rails.root.join("modules/backlogs/db/migrate/20260420160236_remove_version_settings")

RSpec.describe MigrateVersionsToSprints, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let(:project) { create(:project) }
  let(:start_date) { nil }
  let(:effective_date) { nil }
  let(:status) { "open" }
  let(:version_type) { :sprint }
  let!(:version) do
    create(:version, project:, name: "Test Sprint", start_date:, effective_date:, status:)
  end
  let!(:wp1) { create(:work_package, version:, project:) }

  def use_version(as:, version: self.version, project: self.project)
    display = case as
              when :sprint then described_class::MigrationVersionSetting::DISPLAY_LEFT
              when :backlog then described_class::MigrationVersionSetting::DISPLAY_RIGHT
              else 1
              end

    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.execute(<<~SQL.squish)
        INSERT INTO version_settings
          (project_id, version_id, display, created_at, updated_at)
        VALUES (#{project.id}, #{version.id}, #{display}, NOW(), NOW())
      SQL
    end
  end

  around(:all) do |example|
    # In this test: RemoveVersionSettings has already run.
    # In production: RemoveVersionSettings runs after MigrateVersionsToSprints.
    ActiveRecord::Migration.suppress_messages { RemoveVersionSettings.migrate(:down) }
    example.run
    ActiveRecord::Migration.suppress_messages { RemoveVersionSettings.migrate(:up) }
  end

  before { use_version(as: version_type) }

  describe "qualification criteria" do
    let(:start_date)     { Date.new(2026, 1, 1) }
    let(:effective_date) { Date.new(2026, 1, 14) }

    context "when all criteria are met (used in the backlog and work package present)" do
      context "when version is used as a sprint (DISPLAY_LEFT)" do
        it "creates one sprint" do
          expect { migrate }.to change(Sprint, :count).by(1)
        end

        it "copies name, start_date and finish_date" do
          migrate
          sprint = Sprint.last
          expect(sprint.name).to eq("Test Sprint")
          expect(sprint.start_date).to eq(Date.new(2026, 1, 1))
          expect(sprint.finish_date).to eq(Date.new(2026, 1, 14))
        end
      end

      context "when version is used as a backlog (DISPLAY_RIGHT)" do
        let(:version_type) { :backlog }

        it "creates one sprint" do
          expect { migrate }.to change(Sprint, :count).by(1)
        end

        it "copies name, start_date and finish_date" do
          migrate
          sprint = Sprint.last
          expect(sprint.name).to eq("Test Sprint")
          expect(sprint.start_date).to eq(Date.new(2026, 1, 1))
          expect(sprint.finish_date).to eq(Date.new(2026, 1, 14))
        end
      end
    end

    context "when version is not used in the backlog (DISPLAY_NONE)" do
      let(:version_type) { :display_none }

      it "does not create a sprint" do
        expect { migrate }.not_to change(Sprint, :count)
      end
    end

    context "when no work packages are associated with the version" do
      let!(:wp1) { nil }

      it "does not create a sprint" do
        expect { migrate }.not_to change(Sprint, :count)
      end
    end
  end

  describe "date handling" do
    context "when both start_date and effective_date are null" do
      it "creates a sprint with nil dates" do
        expect { migrate }.to change(Sprint, :count).by(1)
        sprint = Sprint.last
        expect(sprint.start_date).to be_nil
        expect(sprint.finish_date).to be_nil
      end
    end

    context "when only effective_date is set" do
      let(:effective_date) { Date.new(2026, 2, 28) }

      it "sets effective_date for finish_date" do
        migrate
        sprint = Sprint.last
        expect(sprint.start_date).to be_nil
        expect(sprint.finish_date).to eq(Date.new(2026, 2, 28))
      end
    end

    context "when only start_date is set" do
      let(:start_date) { Date.new(2026, 2, 1) }

      it "sets start_date for start_date" do
        migrate
        sprint = Sprint.last
        expect(sprint.start_date).to eq(Date.new(2026, 2, 1))
        expect(sprint.finish_date).to be_nil
      end
    end
  end

  describe "status mapping" do
    context "when version status is open" do
      let(:status) { "open" }

      it "creates sprint with in_planning status" do
        migrate
        expect(Sprint.last.status).to eq("in_planning")
      end
    end

    context "when version status is locked" do
      let(:status) { "locked" }

      it "creates sprint with completed status" do
        migrate
        expect(Sprint.last.status).to eq("completed")
      end
    end

    context "when version status is closed" do
      let(:status) { "closed" }

      it "creates sprint with completed status" do
        migrate
        expect(Sprint.last.status).to eq("completed")
      end
    end
  end

  describe "work package association" do
    let!(:wp2) { create(:work_package, version:, project:) }

    it "sets sprint_id on all associated work packages" do
      migrate
      sprint = Sprint.last
      expect(wp1.reload.sprint_id).to eq(sprint.id)
      expect(wp2.reload.sprint_id).to eq(sprint.id)
    end

    it "keeps the version_id on associated work packages" do
      migrate
      expect(wp1.reload.version_id).to eq(version.id)
      expect(wp2.reload.version_id).to eq(version.id)
    end

    context "with multiple versions" do
      let!(:version2) { create(:version, project:, status: "closed") }
      let!(:wp3) { create(:work_package, version: version2, project:) }

      before { use_version(as: :sprint, version: version2) }

      it "assigns work packages to their respective sprints" do
        migrate
        sprints = Sprint.all.index_by(&:name)
        expect(wp1.reload.sprint_id).to eq(sprints[version.name].id)
        expect(wp2.reload.sprint_id).to eq(sprints[version.name].id)
        expect(wp3.reload.sprint_id).to eq(sprints[version2.name].id)
      end
    end

    context "when the version is shared with another project that displays it as backlog" do
      let(:other_project) { create(:project) }
      let!(:wp_in_other_project) { create(:work_package, version:, project: other_project) }

      before { use_version(as: :backlog, project: other_project) }

      it "assigns work packages from both projects" do
        migrate
        sprint = Sprint.last
        expect(wp1.reload.sprint_id).to eq(sprint.id)
        expect(wp2.reload.sprint_id).to eq(sprint.id)
        expect(wp_in_other_project.reload.sprint_id).to eq(sprint.id)
      end
    end

    context "when the version is shared with another project where it is not displayed" do
      let(:other_project) { create(:project) }
      let!(:wp_in_other_project) { create(:work_package, version:, project: other_project) }

      before { use_version(as: :display_none, project: other_project) }

      it "only assigns work packages from the sprint project" do
        migrate
        sprint = Sprint.last
        expect(wp1.reload.sprint_id).to eq(sprint.id)
        expect(wp2.reload.sprint_id).to eq(sprint.id)
        expect(wp_in_other_project.reload.sprint_id).to be_nil
      end
    end
  end

  describe "journal job" do
    it "enqueues MigrateVersionSprintJournalsJob" do
      allow(Backlogs::MigrateVersionSprintJournalsJob).to receive(:perform_later)

      migrate

      expect(Backlogs::MigrateVersionSprintJournalsJob).to have_received(:perform_later)
    end

    context "when version_type is backlog (DISPLAY_RIGHT)" do
      let(:version_type) { :backlog }

      it "enqueues MigrateVersionSprintJournalsJob" do
        allow(Backlogs::MigrateVersionSprintJournalsJob).to receive(:perform_later)

        migrate

        expect(Backlogs::MigrateVersionSprintJournalsJob).to have_received(:perform_later)
      end
    end

    context "when version type is not displayed (DISPLAY_NONE)" do
      let(:version_type) { :display_none }

      it "does not enqueue MigrateVersionSprintJournalsJob" do
        allow(Backlogs::MigrateVersionSprintJournalsJob).to receive(:perform_later)

        migrate

        expect(Backlogs::MigrateVersionSprintJournalsJob).not_to have_received(:perform_later)
      end
    end
  end
end
