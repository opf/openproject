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

RSpec.describe Impediments::CreateService do
  let(:instance) { described_class.new(user:) }
  let(:impediment_subject) { "Impediment A" }

  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: %i(add_work_packages assign_versions work_package_assigned)) }
  let(:type_feature) { create(:type_feature) }
  let(:type_task) { create(:type_task) }
  let(:priority) { create(:priority, is_default: true) }
  let(:feature) do
    build(:work_package,
          type: type_feature,
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

  before do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return("points_burn_direction" => "down",
                                                                       "wiki_template" => "",
                                                                       "story_types" => [type_feature.id.to_s],
                                                                       "task_type" => type_task.id.to_s)

    login_as user
  end

  shared_examples_for "impediment creation" do
    it { expect(subject.subject).to eql impediment_subject }
    it { expect(subject.author).to eql User.current }
    it { expect(subject.project).to eql project }
    it { expect(subject.version).to eql version }
    it { expect(subject.priority).to eql priority }
    it { expect(subject.status).to eql status1 }
    it { expect(subject.type).to eql type_task }
    it { expect(subject.assigned_to).to eql user }
  end

  shared_examples_for "impediment creation with 1 blocking relationship" do
    it_behaves_like "impediment creation"

    it { expect(subject.blocks_relations.size).to eq(1) }
    it { expect(subject.blocks_relations[0].to).to eql feature }
  end

  shared_examples_for "impediment creation with no blocking relationship" do
    it_behaves_like "impediment creation"

    it { expect(subject.blocks_relations.size).to eq(0) }
  end

  describe "WITH a blocking relationship to a story" do
    describe "WITH the story having the same version" do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: feature.id.to_s,
                                           status_id: status1.id,
                                           version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      before do
        feature.version = version
        feature.save
      end

      it_behaves_like "impediment creation with 1 blocking relationship"
      it { expect(subject).not_to be_new_record }
      it { expect(subject.blocks_relations[0]).not_to be_new_record }
    end

    describe "WITH the story having another version" do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: feature.id.to_s,
                                           status_id: status1.id,
                                           version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      before do
        feature.version = create(:version, project:, name: "another version")
        feature.save
      end

      it_behaves_like "impediment creation with no blocking relationship"
      it { expect(subject).to be_new_record }

      it {
        expect(subject.errors.symbols_for(:blocks_ids))
          .to eq [:can_only_contain_work_packages_of_current_sprint]
      }
    end

    describe "WITH the story being non existent" do
      subject do
        call = instance.call(attributes: { subject: impediment_subject,
                                           assigned_to_id: user.id,
                                           priority_id: priority.id,
                                           blocks_ids: "0",
                                           status_id: status1.id,
                                           version_id: version.id,
                                           project_id: project.id })
        call.result
      end

      it_behaves_like "impediment creation with no blocking relationship"
      it { expect(subject).to be_new_record }

      it {
        expect(subject.errors.symbols_for(:blocks_ids))
          .to eq [:can_only_contain_work_packages_of_current_sprint]
      }
    end
  end

  describe "WITHOUT a blocking relationship defined" do
    subject do
      call = instance.call(attributes: { subject: impediment_subject,
                                         assigned_to_id: user.id,
                                         blocks_ids: "",
                                         priority_id: priority.id,
                                         status_id: status1.id,
                                         version_id: version.id,
                                         project_id: project.id })
      call.result
    end

    it_behaves_like "impediment creation with no blocking relationship"
    it { expect(subject).to be_new_record }

    it {
      expect(subject.errors.symbols_for(:blocks_ids))
        .to eq [:must_block_at_least_one_work_package]
    }
  end
end
