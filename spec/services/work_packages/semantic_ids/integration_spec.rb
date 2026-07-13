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

# End-to-end tests verifying that the registry is maintained correctly through
# the full service stack: CreateService, UpdateService, and Projects::UpdateService.
RSpec.describe "SemanticIds registry integration",
               type: :model,
               with_settings: { work_packages_identifier: "semantic" } do
  shared_let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages edit_work_packages move_work_packages edit_project])
  end
  shared_let(:user) { create(:user) }

  let(:project) { create(:project, identifier: "PROJ", wp_sequence_counter: 0) }
  let(:target_project) { create(:project, identifier: "DEST", wp_sequence_counter: 0) }

  before do
    create(:member, principal: user, project:, roles: [role])
    create(:member, principal: user, project: target_project, roles: [role])
    login_as(user)
  end

  describe "find_by guard rejects semantic identifiers" do
    let!(:work_package) { create(:work_package, project:) }

    it "raises ArgumentError for find_by(id:) with a semantic string" do
      expect { WorkPackage.find_by(id: "PROJ-1") }
        .to raise_error(ArgumentError, /find_by_display_id/)
    end

    it "raises ArgumentError for find_by(id:) with a semantic string on a relation" do
      expect { WorkPackage.where(project:).find_by(id: "PROJ-1") }
        .to raise_error(ArgumentError, /find_by_display_id/)
    end
  end

  describe "WP creation via CreateService" do
    let(:attributes) do
      {
        subject: "A new task",
        project:,
        type: project.types.first,
        status: create(:default_status),
        priority: create(:default_priority)
      }
    end

    it "assigns a sequence number, sets identifier, and registers all project-prefix aliases" do
      result = WorkPackages::CreateService.new(user:).call(**attributes)
      expect(result).to be_success

      wp = result.result
      expect(wp.sequence_number).to eq(1)
      expect(wp.identifier).to eq("PROJ-1")
      expect(WorkPackageSemanticAlias.find_by!(work_package: wp).identifier).to eq("PROJ-1")
    end

    it "increments the counter with each new WP" do
      2.times { WorkPackages::CreateService.new(user:).call(**attributes) }
      expect(project.reload.wp_sequence_counter).to eq(2)
      expect(WorkPackageSemanticAlias.where("identifier LIKE 'PROJ-%'").count).to eq(2)
    end
  end

  describe "WP move via UpdateService" do
    let!(:work_package) do
      # after_create auto-registers as PROJ-1; rename entry to PROJ-5 to simulate an established WP
      create(:work_package, project:).tap do |wp|
        wp.update_columns(sequence_number: 5, identifier: "PROJ-5")
        wp.semantic_aliases.update_all(identifier: "PROJ-5")
        project.update_columns(wp_sequence_counter: 5)
      end
    end

    it "preserves the old identifier and appends a new one in the target project" do
      WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)

      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-5")).to be_present
      expect(work_package.reload.identifier).to start_with("DEST-")
    end

    it "allocates sequence numbers in a single batch when moving a WP with descendants" do
      children = create_list(:work_package, 4, project:, parent: work_package)

      WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)

      moved = [work_package, *children].map { |wp| wp.reload.identifier }
      expect(moved).to all(start_with("DEST-"))
      expect(moved.map { |id| id.split("-").last.to_i }).to match_array(1..5)
    end

    it "old identifier still resolves to the WP" do
      WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)
      expect(WorkPackage.find_by_display_id("PROJ-5")).to eq(work_package)
    end

    it "new identifier also resolves to the WP" do
      WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)
      expect(WorkPackage.find_by_display_id(work_package.reload.identifier)).to eq(work_package)
    end

    it "refreshes the in-memory identifier so to_param produces the semantic URL" do
      WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)

      expect(work_package.identifier).to start_with("DEST-")
      expect(work_package.to_param).to start_with("DEST-")
    end
  end

  describe "WP move in classic mode when sequence numbers linger from semantic mode" do
    # The outer before block stubs semantic?: true, so both WPs automatically receive
    # sequence_number = 1 in their respective projects — simulating the state after the
    # user enabled semantic IDs and then switched back to classic.
    let!(:work_package) { create(:work_package, project:) }
    let!(:conflict_wp)  { create(:work_package, project: target_project) }

    before do
      # Simulate the user switching back to classic mode after semantic IDs were active.
      allow(Setting::WorkPackageIdentifier).to receive_messages(semantic?: false, classic?: true)
    end

    it "succeeds without PG::UniqueViolation and clears the sequence number" do
      result = WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)

      expect(result).to be_success
      expect(work_package.reload.project).to eq(target_project)
      expect(work_package.reload.sequence_number).to be_nil
    end

    it "also clears sequence numbers on descendants to avoid conflicts" do
      child = create(:work_package, project:, parent: work_package)
      # Manually assign a sequence_number to the child to simulate leftover semantic state,
      # then create a conflicting WP in the target project with the same sequence number.
      child.update_columns(sequence_number: 2, identifier: "PROJ-2")
      create(:work_package, project: target_project).tap { |wp| wp.update_columns(sequence_number: 2) }

      result = WorkPackages::UpdateService.new(user:, model: work_package).call(project: target_project)

      expect(result).to be_success
      expect(child.reload.sequence_number).to be_nil
    end
  end

  describe "Project rename via Projects::UpdateService" do
    # after_create auto-registers wp1 as "PROJ-1" (seq=1) and wp2 as "PROJ-2" (seq=2)
    let!(:wp1) { create(:work_package, project:) }
    let!(:wp2) { create(:work_package, project:) }

    it "updates identifier on WPs and inserts new-prefix aliases" do
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")

      expect(wp1.reload.identifier).to eq("RENAMED-1")
      expect(wp2.reload.identifier).to eq("RENAMED-2")
      expect(WorkPackageSemanticAlias.find_by(identifier: "RENAMED-1")).to be_present
      expect(WorkPackageSemanticAlias.find_by(identifier: "RENAMED-2")).to be_present
    end

    it "preserves old-prefix entries for historic resolution" do
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")

      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-1")).to be_present
      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-2")).to be_present
    end

    it "old identifiers still resolve to the correct WPs" do
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")

      expect(WorkPackage.find_by_display_id("PROJ-1")).to eq(wp1)
      expect(WorkPackage.find_by_display_id("PROJ-2")).to eq(wp2)
    end

    it "new identifiers resolve to the correct WPs" do
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")

      expect(WorkPackage.find_by_display_id("RENAMED-1")).to eq(wp1)
      expect(WorkPackage.find_by_display_id("RENAMED-2")).to eq(wp2)
    end

    it "old prefix resolves for WPs created after the rename" do
      # wp3 is created after the rename; register_identifier inserts both RENAMED-3
      # (current prefix) and PROJ-3 (historical slug), so both resolve via the alias table.
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")
      wp3 = create(:work_package, project: project.reload)

      expect(WorkPackage.find_by_display_id("RENAMED-3")).to eq(wp3)
      expect(WorkPackage.find_by_display_id("PROJ-3")).to eq(wp3)
    end
  end

  describe "rename + move combinations" do
    let!(:wp1) { create(:work_package, project:) } # auto-registers as PROJ-1

    it "move then rename: old WP identifier resolves under new project prefix" do
      # WP moves to DEST first (retires PROJ-1, creates DEST-1)
      WorkPackages::UpdateService.new(user:, model: wp1).call(project: target_project)
      # PROJ is then renamed to RENAMED (bulk-inserts RENAMED-1 from the retired PROJ-1 row)
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")

      expect(WorkPackage.find_by_display_id("RENAMED-1")).to eq(wp1)
    end

    it "rename then move: both old identifiers resolve after the WP moves" do
      # PROJ renamed to RENAMED (appends RENAMED-1 registry row, updates identifier)
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")
      # WP moves to DEST (appends DEST-1 registry row, updates identifier)
      WorkPackages::UpdateService.new(user:, model: wp1.reload).call(project: target_project)

      expect(WorkPackage.find_by_display_id("PROJ-1")).to eq(wp1)
      expect(WorkPackage.find_by_display_id("RENAMED-1")).to eq(wp1)
    end

    it "rename then new WP then move: pre-rename identifier resolves via alias table" do
      # PROJ renamed to RENAMED; wp1 gets alias PROJ-1, identifier becomes RENAMED-1
      Projects::UpdateService.new(user:, model: project).call(identifier: "RENAMED")
      # wp2 is created in the now-RENAMED project; register_identifier inserts both
      # RENAMED-2 (current prefix) and PROJ-2 (historical slug) into the alias table
      wp2 = create(:work_package, project: project.reload)
      # wp2 moves to DEST — old identifier RENAMED-2 kept as alias, gets DEST-1
      WorkPackages::UpdateService.new(user:, model: wp2).call(project: target_project)

      expect(WorkPackage.find_by_display_id("PROJ-2")).to eq(wp2)
    end
  end

  describe "semantic_identifier_fields_consistent validation does not block service paths" do
    let(:attributes) do
      {
        subject: "A task",
        project:,
        type: project.types.first,
        status: create(:default_status),
        priority: create(:default_priority)
      }
    end

    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      let(:project) { create(:project, wp_sequence_counter: 0) }
      let(:target_project) { create(:project, wp_sequence_counter: 0) }

      it "CreateService succeeds with both identifier fields absent" do
        result = WorkPackages::CreateService.new(user:).call(**attributes)
        expect(result).to be_success
        expect(result.result.identifier).to be_nil
        expect(result.result.sequence_number).to be_nil
      end

      it "UpdateService succeeds when identifier fields remain nil" do
        wp = WorkPackages::CreateService.new(user:).call(**attributes).result
        result = WorkPackages::UpdateService.new(user:, model: wp).call(subject: "Updated subject")
        expect(result).to be_success
      end

      it "UpdateService clears stale identifier fields on a project move" do
        wp = WorkPackages::CreateService.new(user:).call(**attributes).result
        # Simulate a WP that received a semantic id before the instance was
        # switched (back) to classic mode.
        wp.update_columns(identifier: "OLDPROJ-7", sequence_number: 7)

        result = WorkPackages::UpdateService.new(user:, model: wp).call(project: target_project)

        expect(result).to be_success
        expect(wp.identifier).to be_nil
        expect(wp.sequence_number).to be_nil
        expect(wp.reload.identifier).to be_nil
        expect(wp.sequence_number).to be_nil
      end
    end

    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "UpdateService on a plain attribute change does not disturb identifier fields" do
        wp = WorkPackages::CreateService.new(user:).call(**attributes).result
        original_identifier = wp.identifier

        result = WorkPackages::UpdateService.new(user:, model: wp).call(subject: "Updated subject")
        expect(result).to be_success
        expect(wp.reload.identifier).to eq(original_identifier)
        expect(wp.reload.sequence_number).to be_present
      end
    end
  end

  describe "multiple moves" do
    let(:project_c) { create(:project, identifier: "PROJC", wp_sequence_counter: 0) }
    let!(:wp1) { create(:work_package, project:) } # auto-registers as PROJ-1

    before do
      create(:member, principal: user, project: project_c, roles: [role])
    end

    it "all intermediate identifiers resolve after WP moves PROJ → DEST → PROJC" do
      WorkPackages::UpdateService.new(user:, model: wp1).call(project: target_project)
      dest_identifier = wp1.reload.identifier

      WorkPackages::UpdateService.new(user:, model: wp1.reload).call(project: project_c)
      projc_identifier = wp1.reload.identifier

      expect(WorkPackage.find_by_display_id("PROJ-1")).to eq(wp1)
      expect(WorkPackage.find_by_display_id(dest_identifier)).to eq(wp1)
      expect(WorkPackage.find_by_display_id(projc_identifier)).to eq(wp1)
    end
  end
end
