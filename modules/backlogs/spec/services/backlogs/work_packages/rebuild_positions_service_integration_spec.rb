# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Backlogs::WorkPackages::RebuildPositionsService, "integration", type: :model do
  def create_work_package(options)
    container = options[:sprint] || options[:backlog_bucket]
    project = container&.project

    WorkPackage.acts_as_list_no_update do
      create(:work_package, options.reverse_merge(project:, type_id: type.id))
    end
  end

  shared_let(:project1) { create(:project) }
  shared_let(:project2) { create(:project) }
  shared_let(:type) { create(:type) }
  shared_let(:sprint1) { create(:sprint, project: project1, name: "Sprint 1") }
  shared_let(:sprint2) { create(:sprint, project: project1, name: "Sprint 2") }
  shared_let(:sprint3) { create(:sprint, project: project2, name: "Sprint 2") }
  shared_let(:bucket1) { create(:backlog_bucket, project: project1, name: "Bucket 1") }
  shared_let(:bucket2) { create(:backlog_bucket, project: project2, name: "Bucket 2") }

  shared_let(:sprint1_wp1) { create_work_package(subject: "Sprint 1 WorkPackage 1", sprint: sprint1, position: nil) }
  shared_let(:sprint1_wp2) { create_work_package(subject: "Sprint 1 WorkPackage 2", sprint: sprint1, position: 1) }
  shared_let(:sprint1_wp3) { create_work_package(subject: "Sprint 1 WorkPackage 3", sprint: sprint1, position: 2) }
  shared_let(:sprint1_wp4) { create_work_package(subject: "Sprint 1 WorkPackage 4", sprint: sprint1, position: 2) }
  shared_let(:sprint1_wp5) { create_work_package(subject: "Sprint 1 WorkPackage 5", sprint: sprint1, position: nil) }

  shared_let(:sprint2_wp1) { create_work_package(subject: "Sprint 2 WorkPackage 1", sprint: sprint2, position: 3) }
  shared_let(:sprint2_wp2) { create_work_package(subject: "Sprint 2 WorkPackage 2", sprint: sprint2, position: 2) }
  shared_let(:sprint2_wp3) { create_work_package(subject: "Sprint 2 WorkPackage 3", sprint: sprint2, position: 1) }

  shared_let(:sprint3_wp1) { create_work_package(subject: "Sprint 3 WorkPackage 1", sprint: sprint3, position: nil) }
  shared_let(:sprint3_wp2) { create_work_package(subject: "Sprint 3 WorkPackage 2", sprint: sprint3, position: nil) }
  shared_let(:sprint3_wp3) { create_work_package(subject: "Sprint 3 WorkPackage 3", sprint: sprint3, position: nil) }

  shared_let(:inbox_wp1) { create_work_package(subject: "Inbox WorkPackage 1", project: project1, position: nil) }
  shared_let(:inbox_wp2) { create_work_package(subject: "Inbox WorkPackage 2", project: project1, position: nil) }
  shared_let(:inbox_wp3) { create_work_package(subject: "Inbox WorkPackage 3", project: project1, position: nil) }

  shared_let(:bucket1_wp1) { create_work_package(subject: "Bucket 1 WorkPackage 1", backlog_bucket: bucket1, position: nil) }
  shared_let(:bucket1_wp2) { create_work_package(subject: "Bucket 1 WorkPackage 2", backlog_bucket: bucket1, position: 2) }
  shared_let(:bucket1_wp3) { create_work_package(subject: "Bucket 1 WorkPackage 3", backlog_bucket: bucket1, position: 1) }

  shared_let(:bucket2_wp1) { create_work_package(subject: "Bucket 2 WorkPackage 1", backlog_bucket: bucket2, position: nil) }
  shared_let(:bucket2_wp2) { create_work_package(subject: "Bucket 2 WorkPackage 2", backlog_bucket: bucket2, position: nil) }
  shared_let(:bucket2_wp3) { create_work_package(subject: "Bucket 2 WorkPackage 3", backlog_bucket: bucket2, position: nil) }

  def have_positions(**) # rubocop:disable Naming/PredicatePrefix
    pluck(:position).eq(**)
  end

  context "with the project provided" do
    before do
      described_class.new(project: project1).call
    end

    it "fixes the positions in that project while keeping those that have some in the same order" do # rubocop:disable RSpec/ExampleLength
      expect(WorkPackage.where(sprint: sprint1)).to have_positions(
        sprint1_wp2 => 1,
        sprint1_wp3 => 2,
        sprint1_wp4 => 3,
        sprint1_wp1 => 4,
        sprint1_wp5 => 5
      )

      expect(WorkPackage.where(sprint: sprint2)).to have_positions(
        sprint2_wp3 => 1,
        sprint2_wp2 => 2,
        sprint2_wp1 => 3
      )

      expect(WorkPackage.where(sprint: nil, backlog_bucket: nil, project: project1)).to have_positions(
        inbox_wp1 => 1,
        inbox_wp2 => 2,
        inbox_wp3 => 3
      )

      expect(WorkPackage.where(sprint: sprint3)).to have_positions(
        sprint3_wp1 => nil,
        sprint3_wp2 => nil,
        sprint3_wp3 => nil
      )

      expect(WorkPackage.where(backlog_bucket: bucket1)).to have_positions(
        bucket1_wp3 => 1,
        bucket1_wp2 => 2,
        bucket1_wp1 => 3
      )

      expect(WorkPackage.where(backlog_bucket: bucket2)).to have_positions(
        bucket2_wp1 => nil,
        bucket2_wp2 => nil,
        bucket2_wp3 => nil
      )
    end
  end

  context "with a different project provided" do
    before do
      described_class.new(project: project2).call
    end

    it "fixes only the work packages in the other project" do # rubocop:disable RSpec/ExampleLength
      expect(WorkPackage.where(sprint: sprint1)).to have_positions(
        sprint1_wp1 => nil,
        sprint1_wp2 => 1,
        sprint1_wp3 => 2,
        sprint1_wp4 => 2,
        sprint1_wp5 => nil
      )

      expect(WorkPackage.where(sprint: sprint2)).to have_positions(
        sprint2_wp3 => 1,
        sprint2_wp2 => 2,
        sprint2_wp1 => 3
      )

      expect(WorkPackage.where(sprint: nil, backlog_bucket: nil, project: project1)).to have_positions(
        inbox_wp1 => nil,
        inbox_wp2 => nil,
        inbox_wp3 => nil
      )

      expect(WorkPackage.where(sprint: sprint3)).to have_positions(
        sprint3_wp1 => 1,
        sprint3_wp2 => 2,
        sprint3_wp3 => 3
      )

      expect(WorkPackage.where(backlog_bucket: bucket1)).to have_positions(
        bucket1_wp1 => nil,
        bucket1_wp2 => 2,
        bucket1_wp3 => 1
      )

      expect(WorkPackage.where(backlog_bucket: bucket2)).to have_positions(
        bucket2_wp1 => 1,
        bucket2_wp2 => 2,
        bucket2_wp3 => 3
      )
    end
  end

  context "with a no project provided" do
    before do
      described_class.new(project: nil).call
    end

    it "fixes the positions while keeping those that have some in the same order in all projects" do # rubocop:disable RSpec/ExampleLength
      expect(WorkPackage.where(sprint: sprint1)).to have_positions(
        sprint1_wp2 => 1,
        sprint1_wp3 => 2,
        sprint1_wp4 => 3,
        sprint1_wp1 => 4,
        sprint1_wp5 => 5
      )

      expect(WorkPackage.where(sprint: sprint2)).to have_positions(
        sprint2_wp3 => 1,
        sprint2_wp2 => 2,
        sprint2_wp1 => 3
      )

      expect(WorkPackage.where(sprint: nil, backlog_bucket: nil, project: project1)).to have_positions(
        inbox_wp1 => 1,
        inbox_wp2 => 2,
        inbox_wp3 => 3
      )

      expect(WorkPackage.where(sprint: sprint3)).to have_positions(
        sprint3_wp1 => 1,
        sprint3_wp2 => 2,
        sprint3_wp3 => 3
      )

      expect(WorkPackage.where(backlog_bucket: bucket1)).to have_positions(
        bucket1_wp3 => 1,
        bucket1_wp2 => 2,
        bucket1_wp1 => 3
      )

      expect(WorkPackage.where(backlog_bucket: bucket2)).to have_positions(
        bucket2_wp1 => 1,
        bucket2_wp2 => 2,
        bucket2_wp3 => 3
      )
    end
  end
end
