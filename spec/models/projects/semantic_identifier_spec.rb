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

RSpec.describe Projects::SemanticIdentifier, with_settings: { work_packages_identifier: "semantic" } do
  describe "#allocate_wp_semantic_identifier!" do
    let(:project) { create(:project, identifier: "PROJ", wp_sequence_counter: 0) }

    it "returns the allocated sequence number and semantic identifier" do
      seq, identifier = project.allocate_wp_semantic_identifier!
      expect(seq).to eq(1)
      expect(identifier).to eq("PROJ-1")
    end

    it "increments the counter on each successive call" do
      project.allocate_wp_semantic_identifier!
      seq, identifier = project.allocate_wp_semantic_identifier!
      expect(seq).to eq(2)
      expect(identifier).to eq("PROJ-2")
    end

    it "persists the updated counter to the database" do
      project.allocate_wp_semantic_identifier!
      expect(project.reload.wp_sequence_counter).to eq(1)
    end

    it "uses the current project identifier as the prefix" do
      project.update_columns(identifier: "NEWPROJ")
      _, identifier = project.allocate_wp_semantic_identifier!
      expect(identifier).to eq("NEWPROJ-1")
    end
  end

  describe "#reserve_semantic_id_block!" do
    let(:project) { create(:project, identifier: "PROJ") }
    let(:wp1) { create(:work_package, project:) }
    let(:wp2) { create(:work_package, project:) }
    let(:wp3) { create(:work_package, project:) }

    # WPs created in semantic mode already have allocated IDs; reset to a
    # clean slate so reserve_semantic_id_block! can be tested in isolation.
    def reset_wps(*wps)
      ids = wps.map(&:id)
      WorkPackage.where(id: ids).update_all(sequence_number: nil, identifier: nil)
      WorkPackageSemanticAlias.where(work_package_id: ids).delete_all
      project.update_columns(wp_sequence_counter: 0)
    end

    context "with an empty list" do
      it "is a no-op" do
        before_count = project.reload.wp_sequence_counter
        project.reserve_semantic_id_block!([])
        expect(project.reload.wp_sequence_counter).to eq(before_count)
      end

      it "returns an empty hash" do
        expect(project.reserve_semantic_id_block!([])).to eq({})
      end
    end

    context "with work package ids" do
      before { reset_wps(wp1, wp2, wp3) }

      it "advances the counter by the number of ids" do
        project.reserve_semantic_id_block!([wp1.id, wp2.id, wp3.id])
        expect(project.reload.wp_sequence_counter).to eq(3)
      end

      it "allocates all sequence numbers in a single call to allocate_sequence_range!" do
        allow(project).to receive(:allocate_sequence_range!).and_call_original
        project.reserve_semantic_id_block!([wp1.id, wp2.id, wp3.id])
        expect(project).to have_received(:allocate_sequence_range!).with(3).once
      end

      it "assigns consecutive sequence numbers" do
        project.reserve_semantic_id_block!([wp1.id, wp2.id, wp3.id])
        expect(wp1.reload.sequence_number).to eq(1)
        expect(wp2.reload.sequence_number).to eq(2)
        expect(wp3.reload.sequence_number).to eq(3)
      end

      it "sets identifiers to the project-prefix form" do
        project.reserve_semantic_id_block!([wp1.id, wp2.id, wp3.id])
        expect(wp1.reload.identifier).to eq("PROJ-1")
        expect(wp2.reload.identifier).to eq("PROJ-2")
        expect(wp3.reload.identifier).to eq("PROJ-3")
      end

      it "continues from the existing counter value" do
        project.update_columns(wp_sequence_counter: 10)
        project.reserve_semantic_id_block!([wp1.id, wp2.id])
        expect(wp1.reload.sequence_number).to eq(11)
        expect(wp2.reload.sequence_number).to eq(12)
      end

      it "returns the wp_id => identifier assignments produced by the allocation" do
        result = project.reserve_semantic_id_block!([wp1.id, wp2.id, wp3.id])
        expect(result).to eq(wp1.id => "PROJ-1", wp2.id => "PROJ-2", wp3.id => "PROJ-3")
      end

      it "pairs ids with sequence numbers in ascending wp-id order regardless of input order" do
        result = project.reserve_semantic_id_block!([wp3.id, wp1.id, wp2.id])
        sorted_ids = [wp1.id, wp2.id, wp3.id]
        expect(result).to eq(sorted_ids[0] => "PROJ-1", sorted_ids[1] => "PROJ-2", sorted_ids[2] => "PROJ-3")
      end

      context "when insert_aliases: true (default)" do
        it "creates alias rows for each slug prefix" do
          project.reserve_semantic_id_block!([wp1.id, wp2.id])
          expect(WorkPackageSemanticAlias.where(work_package: wp1).pluck(:identifier))
            .to contain_exactly("PROJ-1")
          expect(WorkPackageSemanticAlias.where(work_package: wp2).pluck(:identifier))
            .to contain_exactly("PROJ-2")
        end

        it "creates alias rows for all historical slug prefixes" do
          FriendlyId::Slug.create!(sluggable: project, slug: "OLDPROJ")
          project.reserve_semantic_id_block!([wp1.id])
          expect(WorkPackageSemanticAlias.where(work_package: wp1).pluck(:identifier))
            .to contain_exactly("PROJ-1", "OLDPROJ-1")
        end
      end

      context "when insert_aliases: false" do
        it "skips alias insertion" do
          project.reserve_semantic_id_block!([wp1.id, wp2.id], insert_aliases: false)
          expect(WorkPackageSemanticAlias.where(work_package: [wp1, wp2])).not_to exist
        end
      end
    end
  end

  describe "#handle_semantic_rename" do
    let(:project) { create(:project, identifier: "PROJ", wp_sequence_counter: 0) }
    let(:target_project) { create(:project, identifier: "OTHER", wp_sequence_counter: 0) }
    let(:wp1) { create(:work_package, project:) }
    let(:wp2) { create(:work_package, project:) }

    before do
      wp1
      wp2
      project.update_columns(identifier: "NEWPROJ")
    end

    it "preserves old-prefix aliases for resident WPs" do
      project.handle_semantic_rename("PROJ")
      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-1")).to be_present
      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-2")).to be_present
    end

    it "adds new-prefix aliases for resident WPs" do
      project.handle_semantic_rename("PROJ")
      expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-1")).to be_present
      expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-2")).to be_present
    end

    it "updates identifier on resident WPs to the new prefix" do
      project.handle_semantic_rename("PROJ")
      expect(wp1.reload.identifier).to eq("NEWPROJ-1")
      expect(wp2.reload.identifier).to eq("NEWPROJ-2")
    end

    it "is idempotent (safe to run twice)" do
      project.handle_semantic_rename("PROJ")
      expect { project.handle_semantic_rename("PROJ") }.not_to raise_error
    end

    context "when records span multiple batches" do
      let(:wp3) { create(:work_package, project:) }

      before { wp3 }

      it "processes all aliases across batch boundaries" do
        project.handle_semantic_rename("PROJ", batch_size: 2)
        expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-1")).to be_present
        expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-2")).to be_present
        expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-3")).to be_present
      end

      it "rewrites all WP identifiers across batch boundaries" do
        project.handle_semantic_rename("PROJ", batch_size: 2)
        expect(wp1.reload.identifier).to eq("NEWPROJ-1")
        expect(wp2.reload.identifier).to eq("NEWPROJ-2")
        expect(wp3.reload.identifier).to eq("NEWPROJ-3")
      end
    end

    context "when a WP has previously moved out of the project" do
      before do
        # Move wp1 to OTHER properly so "PROJ-1" ends up as an alias
        wp1.update_columns(project_id: target_project.id)
        wp1.allocate_and_register_semantic_id
      end

      it "appends a new-prefix alias derived from the old alias row" do
        project.handle_semantic_rename("PROJ")
        expect(WorkPackageSemanticAlias.find_by(identifier: "NEWPROJ-1")).to be_present
      end

      it "preserves the original old-prefix alias" do
        project.handle_semantic_rename("PROJ")
        expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-1")).to be_present
      end

      it "does not update identifier on the moved-away WP" do
        project.handle_semantic_rename("PROJ")
        expect(wp1.reload.identifier).to eq("OTHER-1")
      end
    end
  end

  describe "relation-scoped finder methods" do
    let(:project) { create(:project, identifier: "PROJ", wp_sequence_counter: 0) }
    let(:other_project) { create(:project, identifier: "OTHER", wp_sequence_counter: 0) }
    let!(:wp1) { create(:work_package, project:) }
    let!(:wp2) { create(:work_package, project: other_project) }

    describe "project.work_packages.find" do
      it "resolves a semantic identifier scoped to the project" do
        expect(project.work_packages.find("PROJ-1")).to eq(wp1)
      end

      it "raises RecordNotFound for a WP belonging to another project" do
        expect { project.work_packages.find("OTHER-1") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises RecordNotFound for unknown semantic id" do
        expect { project.work_packages.find("PROJ-999") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "resolves via historic alias" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package: wp1)
        expect(project.work_packages.find("OLDPROJ-1")).to eq(wp1)
      end
    end

    describe "project.work_packages.exists?" do
      it "returns true for a semantic identifier within the project" do
        expect(project.work_packages.exists?("PROJ-1")).to be true
      end

      it "returns false for a WP belonging to another project" do
        expect(project.work_packages.exists?("OTHER-1")).to be false
      end

      it "returns false for unknown semantic id" do
        expect(project.work_packages.exists?("PROJ-999")).to be false
      end

      it "checks the alias table for historical identifiers" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package: wp1)
        expect(project.work_packages.exists?("OLDPROJ-1")).to be true
      end
    end

    describe "project.work_packages.find_by_display_id" do
      it "resolves a semantic identifier scoped to the project" do
        expect(project.work_packages.find_by_display_id("PROJ-1")).to eq(wp1)
      end

      it "returns nil for a WP belonging to another project" do
        expect(project.work_packages.find_by_display_id("OTHER-1")).to be_nil
      end

      it "returns nil for unknown semantic id" do
        expect(project.work_packages.find_by_display_id("PROJ-999")).to be_nil
      end
    end
  end
end
