#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'rails_helper'

RSpec.describe WorkPackages::ScheduleDependency::Dependency do
  subject { described_class.new(work_package, schedule_dependency) }

  let(:work_package) { create(:work_package, subject: 'subject') }
  let(:schedule_dependency) { instance_double(WorkPackages::ScheduleDependency) }
  let(:known_work_packages_by_parent_id) { Hash.new { |h, k| h[k] = [] } }
  let(:known_work_packages_by_id) { { work_package.id => work_package } }

  before do
    allow(schedule_dependency)
      .to receive(:known_work_packages_by_parent_id)
      .and_return(known_work_packages_by_parent_id)
    allow(schedule_dependency)
      .to receive(:known_work_packages_by_id)
      .and_return(known_work_packages_by_id)
    allow(schedule_dependency)
      .to receive(:scheduled_work_packages_by_id)
      .and_return(known_work_packages_by_id)
  end

  def create_predecessor_of(work_package)
    create(:work_package, subject: "predecessor of #{work_package.subject}").tap do |predecessor|
      create(:follows_relation, from: work_package, to: predecessor)
      known_work_packages_by_id[predecessor.id] = predecessor
    end
  end

  def create_follower_of(work_package)
    create(:work_package, subject: "follower of #{work_package.subject}").tap do |follower|
      create(:follows_relation, from: follower, to: work_package)
      known_work_packages_by_id[follower.id] = follower
    end
  end

  def create_parent_of(work_package)
    create(:work_package, subject: "parent of #{work_package.subject}", parent: work_package).tap do |parent|
      known_work_packages_by_id[parent.id] = parent
      known_work_packages_by_parent_id[work_package.parent_id] << parent
    end
  end

  def create_child_of(work_package)
    create(:work_package, subject: "child of #{work_package.subject}", parent: work_package).tap do |child|
      known_work_packages_by_id[child.id] = child
      known_work_packages_by_parent_id[child.parent_id] << child
    end
  end

  describe '#dependent_ids' do
    context 'when the work_package is not related to anything' do
      it 'returns empty array' do
        expect(subject.dependent_ids).to eq([])
      end
    end

    context 'when the work_package has a predecessor' do
      let!(:predecessor) { create_predecessor_of(work_package) }

      it 'returns an array with the predecessor id' do
        expect(subject.dependent_ids).to eq([predecessor.id])
      end
    end

    context 'when the work_package has a follower' do
      let!(:follower) { create_follower_of(work_package) }

      it 'returns empty array' do
        expect(subject.dependent_ids).to eq([])
      end
    end

    context 'when the work_package has a parent' do
      let!(:parent) { create_parent_of(work_package) }

      it 'returns empty array' do
        expect(subject.dependent_ids).to eq([])
      end
    end

    context 'when the work_package has a child' do
      let!(:child) { create_child_of(work_package) }

      it 'returns an array with the child id' do
        expect(subject.dependent_ids).to eq([child.id])
      end
    end

    context 'when the work_package has multiple children and predecessors' do
      let!(:child1) { create_child_of(work_package) }
      let!(:child2) { create_child_of(work_package) }
      let!(:predecessor1) { create_predecessor_of(work_package) }
      let!(:predecessor2) { create_predecessor_of(work_package) }

      it 'returns an array with the children and the predecessors ids' do
        expect(subject.dependent_ids).to contain_exactly(child1.id, child2.id, predecessor1.id, predecessor2.id)
      end
    end

    context 'with more complex relations' do
      context 'when has a child which has a child' do
        let!(:child) { create_child_of(work_package) }
        let!(:child_child) { create_child_of(child) }

        it 'returns an array with both children ids' do
          expect(subject.dependent_ids).to contain_exactly(child.id, child_child.id)
        end
      end

      context 'when has a predecessor which has a predecessor and a follower' do
        let!(:predecessor) { create_predecessor_of(work_package) }
        let!(:predecessor_predecessor) { create_predecessor_of(predecessor) }
        let!(:predecessor_follower) { create_follower_of(predecessor) }

        it 'returns an array with the first predecessor only (not transient)' do
          expect(subject.dependent_ids).to contain_exactly(predecessor.id)
        end
      end

      context 'when has a predecessor which has a parent and a child' do
        let!(:predecessor) { create_predecessor_of(work_package) }
        let!(:predecessor_parent) { create_parent_of(predecessor) }
        let!(:predecessor_child) { create_child_of(predecessor) }

        it 'returns an array with the predecessor only (not transient)' do
          expect(subject.dependent_ids).to contain_exactly(predecessor.id)
        end
      end
    end
  end
end
