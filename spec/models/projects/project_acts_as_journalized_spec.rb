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
      expect(Journal.all.count).to eq(1)
      expect(Journal.first.journable).to eq(project)
    end

    it "notes the changes to name" do
      expect(Journal.first.details[:name])
        .to contain_exactly(nil, project.name)
    end

    it "notes the changes to description" do
      expect(Journal.first.details[:description])
        .to contain_exactly(nil, project.description)
    end

    it "notes the changes to public flag" do
      expect(Journal.first.details[:public])
        .to contain_exactly(nil, project.public)
    end

    it "notes the changes to identifier" do
      expect(Journal.first.details[:identifier])
        .to contain_exactly(nil, project.identifier)
    end

    it "notes the changes to active flag" do
      expect(Journal.first.details[:active])
        .to contain_exactly(nil, project.active)
    end

    it "notes the changes to template flag" do
      expect(Journal.first.details[:templated])
        .to contain_exactly(nil, project.templated)
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
    let(:custom_field_id) { "custom_fields_#{custom_value.custom_field_id}" }

    shared_context "for project with new custom value" do
      before do
        project.update(custom_values: [custom_value])
      end
    end

    context "for new custom value" do
      include_context "for project with new custom value"

      it "contains the new custom value change" do
        expect(project.last_journal.details)
          .to include(custom_field_id => [nil, custom_value.value])
      end
    end

    context "for updated custom value" do
      include_context "for project with new custom value"

      let(:modified_custom_value) do
        build(:custom_value,
              value: "some modified value for project custom field",
              custom_field:)
      end

      before do
        project.update(custom_values: [modified_custom_value])
      end

      it "contains the change from previous value to updated value" do
        expect(project.last_journal.details)
          .to include(custom_field_id => [custom_value.value, modified_custom_value.value])
      end
    end

    context "when project saved without any changes" do
      include_context "for project with new custom value"

      let(:unmodified_custom_value) do
        build(:custom_value,
              value: custom_value.value,
              custom_field:)
      end

      before do
        project.custom_values = [unmodified_custom_value]
      end

      it { expect { project.save! }.not_to change(Journal, :count) }
    end

    context "when custom value removed" do
      include_context "for project with new custom value"

      before do
        project.update(custom_values: [])
      end

      it "contains the change from previous value to nil" do
        expect(project.last_journal.details)
          .to include(custom_field_id => [custom_value.value, nil])
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
      project.destroy
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
