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

RSpec.describe Impediments::UpdateService, type: :model do
  let(:instance) { described_class.new(user:, impediment:) }

  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: %i(edit_work_packages view_work_packages)) }
  let(:type_feature) { create(:type_feature) }
  let(:type_task) { create(:type_task) }
  let(:priority) { impediment.priority }
  let(:task) do
    build(:task, type: type_task,
                 project:,
                 author: user,
                 priority:,
                 status: status1)
  end
  let(:feature) do
    build(:work_package, type: type_feature,
                         project:,
                         author: user,
                         priority:,
                         status: status1)
  end
  let(:version) { create(:version, project:) }

  let(:project) do
    project = create(:project, types: [type_feature, type_task])

    create(:member, principal: user,
                    project:,
                    roles: [role])

    project
  end

  let(:status1) { create(:status, name: "status 1", is_default: true) }
  let(:status2) { create(:status, name: "status 2") }
  let(:type_workflow) do
    Workflow.create(type_id: type_task.id,
                    old_status: status1,
                    new_status: status2,
                    role:)
  end
  let(:impediment) do
    build(:impediment, author: user,
                       version:,
                       assigned_to: user,
                       project:,
                       type: type_task,
                       status: status1)
  end

  before do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "points_burn_direction" => "down",
                                                                         "wiki_template" => "",
                                                                         "story_types" => [type_feature.id.to_s],
                                                                         "task_type" => type_task.id.to_s })

    login_as user

    status1.save
    project.save
    type_workflow.save

    feature.version = version
    feature.save

    impediment.blocks_ids = feature.id.to_s
    impediment.save
  end

  shared_examples_for "impediment update" do
    it { expect(subject.author).to eql user }
    it { expect(subject.project).to eql project }
    it { expect(subject.version).to eql version }
    it { expect(subject.priority).to eql priority }
    it { expect(subject.status).to eql status2 }
    it { expect(subject.type).to eql type_task }
    it { expect(subject.blocks_ids).to eql blocks.split(/\D+/).map(&:to_i) }
  end

  shared_examples_for "impediment update with changed blocking relationship" do
    it_behaves_like "impediment update"
    it { expect(subject.relations.size).to eq(1) }
    it { expect(subject.relations[0]).not_to be_new_record }
    it { expect(subject.relations[0].to).to eql story }
    it { expect(subject.relations[0].relation_type).to eql Relation::TYPE_BLOCKS }
  end

  shared_examples_for "impediment update with unchanged blocking relationship" do
    it_behaves_like "impediment update"
    it { expect(subject.relations.size).to eq(1) }
    it { expect(subject.relations[0]).not_to be_changed }
    it { expect(subject.relations[0].to).to eql feature }
    it { expect(subject.relations[0].relation_type).to eql Relation::TYPE_BLOCKS }
  end

  subject do
    call = instance.call(attributes: { blocks_ids: blocks,
                                       status_id: status2.id.to_s })

    call.result
  end

  describe "WHEN changing the blocking relationship to another story" do
    let(:story) do
      build(:work_package,
            subject: "another story",
            type: type_feature,
            project:,
            author: user,
            priority:,
            status: status1)
    end
    let(:blocks) { story.id.to_s }
    let(:story_version) { version }

    before do
      story.version = story_version
      story.save!
    end

    describe "WITH the story having the same version" do
      it_behaves_like "impediment update with changed blocking relationship"
      it { expect(subject).not_to be_changed }
    end

    describe "WITH the story having another version" do
      let(:story_version) { create(:version, project:, name: "another version") }

      it_behaves_like "impediment update with unchanged blocking relationship"
      it "is not saved successfully" do
        expect(subject).to be_changed
      end

      it {
        expect(subject.errors.symbols_for(:blocks_ids))
          .to eq [:can_only_contain_work_packages_of_current_sprint]
      }
    end

    describe "WITH the story being non existent" do
      let(:blocks) { "0" }

      it_behaves_like "impediment update with unchanged blocking relationship"
      it "is not saved successfully" do
        expect(subject).to be_changed
      end

      it {
        expect(subject.errors.symbols_for(:blocks_ids))
          .to eq [:can_only_contain_work_packages_of_current_sprint]
      }
    end
  end

  describe "WITHOUT a blocking relationship defined" do
    let(:blocks) { "" }

    it_behaves_like "impediment update with unchanged blocking relationship"
    it "is not saved successfully" do
      expect(subject).to be_changed
    end

    it {
      expect(subject.errors.symbols_for(:blocks_ids))
        .to eq [:must_block_at_least_one_work_package]
    }
  end
end
