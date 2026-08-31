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

RSpec.describe Project, "acts_as_journalized" do
  shared_let(:user) { create(:user) }

  let!(:project) do
    User.execute_as user do
      create(:project,
             description: "project description")
    end
  end

  context "on project creation" do
    it "has one journal entry" do
      expect(Journal.count).to eq(1)
      expect(Journal.first.journable).to eq(project)
    end

    it "notes the changes to name" do
      expect(Journal.first.details[:name])
        .to eql([nil, project.name])
    end

    it "notes the changes to description" do
      expect(Journal.first.details[:description])
        .to eql([nil, project.description])
    end

    it "notes the changes to public flag" do
      expect(Journal.first.details[:public])
        .to eql([nil, project.public])
    end

    it "notes the changes to identifier" do
      expect(Journal.first.details[:identifier])
        .to eql([nil, project.identifier])
    end

    it "notes the changes to active flag" do
      expect(Journal.first.details[:active])
        .to eql([nil, project.active])
    end

    it "notes the changes to template flag" do
      expect(Journal.first.details[:templated])
        .to eql([nil, project.templated])
    end

    it "has the timestamp of the project update time for created_at" do
      expect(Journal.first.created_at)
        .to eql(project.reload.updated_at)
    end
  end

  context "when nothing is changed" do
    it { expect { project.save! }.not_to change(Journal, :count) }
  end

  describe "on project update", with_settings: { journal_aggregation_time_minutes: 0 } do
    shared_let(:parent_project) { create(:project) }

    before do
      project.name = "changed project name"
      project.description = "changed project description"
      project.public = !project.public
      project.parent = parent_project
      project.identifier = "changed-identifier"
      project.active = !project.active
      project.templated = !project.templated

      project.save!
    end

    context "for last created journal" do
      it "has the timestamp of the project update time for created_at" do
        expect(project.last_journal.created_at)
          .to eql(project.reload.updated_at)
      end

      it "contains last changes" do
        %i[name description public parent_id identifier active templated].each do |prop|
          expect(project.last_journal.details).to have_key(prop.to_s), "Missing change for #{prop}"
        end
      end
    end
  end

  describe "custom values", with_settings: { journal_aggregation_time_minutes: 0 } do
    shared_let(:custom_field) { create(:string_project_custom_field) }
    let(:custom_value) do
      build(:custom_value,
            value: "some string value for project custom field",
            custom_field:)
    end
    let(:modified_custom_value) do
      build(:custom_value,
            value: "some modified value for project custom field",
            custom_field:)
    end
    let(:custom_field_key) { "custom_fields_#{custom_field.id}" }

    shared_examples "contains the expected change" do
      it "contains the expected change" do
        expect(project.last_journal.details).to include(custom_field_key => expected_change)
      end
    end

    context "for new custom value" do
      let(:expected_change) { [nil, custom_value.value] }

      before do
        project.update!(custom_values: [custom_value])
      end

      include_examples "contains the expected change"
    end

    context "for updated custom value" do
      let(:expected_change) { [custom_value.value, modified_custom_value.value] }

      before do
        User.execute_as user do
          project.update!(custom_values: [custom_value])
        end

        project.update!(custom_values: [modified_custom_value])
      end

      include_examples "contains the expected change"
    end

    context "when custom value removed" do
      let(:expected_change) { [custom_value.value, nil] }

      before do
        User.execute_as user do
          project.update!(custom_values: [custom_value])
        end

        project.update!(custom_values: [])
      end

      include_examples "contains the expected change"
    end

    context "when project saved without any changes" do
      let(:unmodified_custom_value) do
        build(:custom_value,
              value: custom_value.value,
              custom_field:)
      end

      before do
        User.execute_as user do
          project.update!(custom_values: [custom_value])
        end

        project.custom_values = [unmodified_custom_value]
      end

      it { expect { project.save! }.not_to change(Journal, :count) }
    end

    context "when custom field gets disabled" do
      let(:expected_change) { [custom_value.value, nil] }

      before do
        User.execute_as user do
          project.update!(custom_values: [custom_value])
        end

        project.update!(custom_values: [modified_custom_value])
        project.project_custom_field_project_mappings.where(custom_field_id: custom_field.id).delete_all
        project.save_journals
      end

      it "contains no change for the disabled custom field (removed when fetching)" do
        expect(project.last_journal.details).not_to have_key(custom_field_key)
      end
    end

    context "if custom field is marked for all" do
      let(:expected_change) { [custom_value.value, modified_custom_value.value] }

      before do
        User.execute_as user do
          project.update!(custom_values: [custom_value])
        end

        project.update!(custom_values: [modified_custom_value])
        custom_field.update!(is_for_all: true)
        project.project_custom_field_project_mappings.where(custom_field_id: custom_field.id).delete_all
        project.save_journals
      end

      it "contains no change for the disabled custom field (removed when fetching)" do
        expect(project.last_journal.details).not_to have_key(custom_field_key)
      end
    end
  end

  describe "custom comments" do
    let!(:custom_field) { create(:string_project_custom_field, :has_comment, projects: [project]) }
    let(:custom_comment_key) { "custom_comment_#{custom_field.id}" }
    let(:custom_comment_text) { "some descriptive comment" }
    let(:modified_custom_comment_text) { "a more descriptive comment" }

    shared_examples "contains the expected change" do
      it "contains the expected change" do
        expect(project.last_journal.details).to include(custom_comment_key => expected_change)
      end
    end

    context "for new custom comment" do
      let(:expected_change) { [nil, custom_comment_text] }

      before do
        project.update!(custom_comments: { custom_field.id => custom_comment_text })
      end

      include_examples "contains the expected change"
    end

    context "for updated custom comment" do
      let(:expected_change) { [custom_comment_text, modified_custom_comment_text] }

      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.update!(custom_comments: { custom_field.id => modified_custom_comment_text })
      end

      include_examples "contains the expected change"
    end

    context "for removed custom comment" do
      let(:expected_change) { [custom_comment_text, nil] }

      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.update!(custom_comments: { custom_field.id => "" })
      end

      include_examples "contains the expected change"
    end

    context "when project saved without any changes" do
      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.custom_comments = { custom_field.id => custom_comment_text }
      end

      it { expect { project.save! }.not_to change(Journal, :count) }
    end

    context "when custom field gets disabled" do
      let(:expected_change) { [custom_comment_text, nil] }

      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.update!(custom_comments: { custom_field.id => modified_custom_comment_text })
        project.project_custom_field_project_mappings.where(custom_field_id: custom_field.id).delete_all
        project.save_journals
      end

      include_examples "contains the expected change"
    end

    context "if custom field is marked for all" do
      let(:expected_change) { [custom_comment_text, modified_custom_comment_text] }

      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.update!(custom_comments: { custom_field.id => modified_custom_comment_text })
        custom_field.update!(is_for_all: true)
        project.project_custom_field_project_mappings.where(custom_field_id: custom_field.id).delete_all
        project.save_journals
      end

      include_examples "contains the expected change"
    end

    context "if custom field is marked as not having comments" do
      let(:expected_change) { [custom_comment_text, nil] }

      before do
        User.execute_as user do
          project.update!(custom_comments: { custom_field.id => custom_comment_text })
        end

        project.update!(custom_comments: { custom_field.id => modified_custom_comment_text })
        custom_field.update!(has_comment: false)
        project.save_journals
      end

      include_examples "contains the expected change"
    end
  end

  describe "phases", with_settings: { journal_aggregation_time_minutes: 0 } do
    describe "activation/deactivation" do
      let(:phase1) { build(:project_phase, project:, active: true, start_date: nil, finish_date: nil) }
      let(:phase2) { build(:project_phase, project:, active: false, start_date: nil, finish_date: nil) }
      let(:phase3) { build(:project_phase, project:, active: true, start_date: nil, finish_date: nil) }

      context "when adding" do
        it "contains the change" do
          project.update!(phases: [phase1, phase2])

          expect(project.last_journal.details).to eq(
            {
              "project_phase_#{phase1.id}_active" => [nil, true],
              "project_phase_#{phase2.id}_active" => [nil, false]
            }
          )
        end
      end

      context "when updating" do
        before do
          project.update!(phases: [phase1, phase2, phase3])
        end

        it "contains the change" do
          phase1.update!(active: false)
          phase2.update!(active: true)
          project.save!

          expect(project.last_journal.details).to eq(
            {
              "project_phase_#{phase1.id}_active" => [true, false],
              "project_phase_#{phase2.id}_active" => [false, true]
            }
          )
        end
      end
    end

    describe "modifying dates" do
      let!(:phase1) { create(:project_phase, project:, start_date: original1&.begin, finish_date: original1&.end) }
      let!(:phase2) { create(:project_phase, project:, start_date: original2&.begin, finish_date: original2&.end) }
      let!(:phase3) { create(:project_phase, project:, start_date: original3&.begin, finish_date: original3&.end) }
      let!(:phase4) { create(:project_phase, project:, start_date: original4&.begin, finish_date: original4&.end) }

      before do
        project.save!
      end

      context "when setting dates" do
        let(:original1) { nil }
        let(:original2) { nil }
        let(:original3) { nil }
        let(:original4) { nil }

        it "contains the change" do
          phase1.update!(start_date: Date.new(2025, 1, 28), finish_date: Date.new(2025, 1, 29))
          phase2.update!(start_date: Date.new(2025, 1, 30), finish_date: Date.new(2025, 1, 31))
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_phase_#{phase1.id}_date_range" => [
                nil,
                Date.new(2025, 1, 28)..Date.new(2025, 1, 29)
              ],
              "project_phase_#{phase2.id}_date_range" => [
                nil,
                Date.new(2025, 1, 30)..Date.new(2025, 1, 31)
              ]
            }
          )
        end
      end

      context "when changing dates" do
        let(:original1) { Date.new(2025, 1, 5)..Date.new(2025, 1, 7) }
        let(:original2) { Date.new(2025, 1, 15)..Date.new(2025, 1, 17) }
        let(:original3) { Date.new(2025, 1, 25)..Date.new(2025, 1, 27) }
        let(:original4) { Date.new(2025, 2, 5)..Date.new(2025, 2, 7) }

        it "contains the change" do
          phase1.update!(start_date: Date.new(2025, 1, 1), finish_date: Date.new(2025, 1, 7))
          phase2.update!(start_date: Date.new(2025, 1, 16), finish_date: Date.new(2025, 1, 18))
          phase3.update!(start_date: Date.new(2025, 1, 25), finish_date: Date.new(2025, 1, 31))
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_phase_#{phase1.id}_date_range" => [
                Date.new(2025, 1, 5)..Date.new(2025, 1, 7),
                Date.new(2025, 1, 1)..Date.new(2025, 1, 7)
              ],
              "project_phase_#{phase2.id}_date_range" => [
                Date.new(2025, 1, 15)..Date.new(2025, 1, 17),
                Date.new(2025, 1, 16)..Date.new(2025, 1, 18)
              ],
              "project_phase_#{phase3.id}_date_range" => [
                Date.new(2025, 1, 25)..Date.new(2025, 1, 27),
                Date.new(2025, 1, 25)..Date.new(2025, 1, 31)
              ]
            }
          )
        end
      end

      context "when removing dates" do
        let(:original1) { Date.new(2025, 1, 5)..Date.new(2025, 1, 7) }
        let(:original2) { Date.new(2025, 1, 15)..Date.new(2025, 1, 17) }
        let(:original3) { Date.new(2025, 1, 25)..Date.new(2025, 1, 27) }
        let(:original4) { Date.new(2025, 2, 5)..Date.new(2025, 2, 7) }

        it "contains the change" do
          phase1.update!(start_date: nil, finish_date: nil)
          phase2.update!(start_date: nil, finish_date: nil)
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_phase_#{phase1.id}_date_range" => [
                Date.new(2025, 1, 5)..Date.new(2025, 1, 7),
                nil
              ],
              "project_phase_#{phase2.id}_date_range" => [
                Date.new(2025, 1, 15)..Date.new(2025, 1, 17),
                nil
              ]
            }
          )
        end
      end
    end

    describe "combined" do
      let(:phase1) do
        build(:project_phase, project:, active: true, start_date: Date.new(2025, 1, 28), finish_date: Date.new(2025, 1, 29))
      end
      let(:phase2) do
        build(:project_phase, project:, active: false, start_date: Date.new(2025, 1, 30), finish_date: Date.new(2025, 1, 31))
      end

      it "contains both changes" do
        project.update!(phases: [phase1, phase2])

        expect(project.last_journal.details).to match(
          {
            "project_phase_#{phase1.id}_active" => [nil, true],
            "project_phase_#{phase1.id}_date_range" => [nil, Date.new(2025, 1, 28)..Date.new(2025, 1, 29)],
            "project_phase_#{phase2.id}_active" => [nil, false],
            "project_phase_#{phase2.id}_date_range" => [nil, Date.new(2025, 1, 30)..Date.new(2025, 1, 31)]
          }
        )
      end
    end

    describe "when creating without touching project" do
      let!(:project) do
        Timecop.freeze(1.year.ago) do
          create(:project)
        end
      end

      before do
        create(:project_phase, project_id: project.id)
      end

      it "succeeds when using save_journals" do
        expect do
          project.save_journals
        end.to change { project.journals.count }.from(1).to(2)
      end

      it "succeeds when using touch_and_save_journals" do
        expect do
          project.touch_and_save_journals
        end.to change { project.journals.count }.from(1).to(2)
      end
    end
  end

  describe "on project deletion" do
    shared_let(:custom_field) { create(:string_project_custom_field) }
    let(:custom_value) do
      build(:custom_value,
            value: "some string value for project custom field",
            custom_field:)
    end
    let!(:project) do
      User.execute_as user do
        create(:project, custom_values: [custom_value])
      end
    end
    let!(:journal) { project.last_journal }
    let!(:customizable_journals) { journal.customizable_journals }

    before do
      project.destroy!
    end

    it "removes the journal" do
      expect(Journal.find_by(id: journal.id))
        .to be_nil
    end

    it "removes the journal data" do
      expect(Journal::ProjectJournal.find_by(id: journal.data_id))
        .to be_nil
    end

    it "removes the customizable journals" do
      expect(Journal::CustomizableJournal.find_by(id: customizable_journals.map(&:id)))
        .to be_nil
    end
  end
end
