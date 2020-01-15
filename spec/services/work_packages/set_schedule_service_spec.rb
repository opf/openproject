#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::SetScheduleService do
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             start_date: work_package_start_date,
                             due_date: work_package_due_date)
  end
  let(:work_package_due_date) { Date.today }
  let(:work_package_start_date) { nil }
  let(:instance) do
    described_class.new(user: user, work_package: work_package)
  end
  let(:following) do
    { [work_package] => [] }
  end
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:type) { FactoryBot.build_stubbed(:type) }

  def stub_follower(start_date, due_date, predecessors)
    work_package = FactoryBot.build_stubbed(:stubbed_work_package,
                                            type: type,
                                            start_date: start_date,
                                            due_date: due_date)

    relations = predecessors.map do |predecessor, delay|
      FactoryBot.build_stubbed(:follows_relation,
                               delay: delay,
                               from: work_package,
                               to: predecessor)
    end

    allow(work_package)
      .to receive(:follows_relations)
            .and_return relations

    work_package
  end

  def stub_follower_child(parent, start, due)
    child = stub_follower(start,
                          due,
                          {})

    relation = FactoryBot.build_stubbed(:hierarchy_relation,
                                        from: parent,
                                        to: child)

    allow(child)
      .to receive(:parent_relation)
            .and_return relation

    child
  end

  let(:follower1_start_date) { Date.today + 1.day }
  let(:follower1_due_date) { Date.today + 3.day }
  let(:follower1_delay) { 0 }
  let(:following_work_package1) do
    stub_follower(follower1_start_date,
                  follower1_due_date,
                  work_package => follower1_delay)
  end
  let(:follower2_start_date) { Date.today + 4.day }
  let(:follower2_due_date) { Date.today + 8.day }
  let(:follower2_delay) { 0 }
  let(:following_work_package2) do
    stub_follower(follower2_start_date,
                  follower2_due_date,
                  following_work_package1 => follower2_delay)
  end
  let(:follower3_start_date) { Date.today + 9.day }
  let(:follower3_due_date) { Date.today + 10.day }
  let(:follower3_delay) { 0 }
  let(:following_work_package3) do
    stub_follower(follower3_start_date,
                  follower3_due_date,
                  following_work_package2 => follower3_delay)
  end

  let(:parent_follower1_start_date) { follower1_start_date }
  let(:parent_follower1_due_date) { follower1_due_date }

  let(:parent_following_work_package1) do
    work_package = stub_follower(parent_follower1_start_date,
                                 parent_follower1_due_date,
                                 {})

    relation = FactoryBot.build_stubbed(:hierarchy_relation,
                                        from: work_package,
                                        to: following_work_package1)

    allow(following_work_package1)
      .to receive(:parent_relation)
            .and_return relation

    work_package
  end

  let(:follower_sibling_work_package) do
    sibling = stub_follower(follower1_due_date + 2.days,
                            follower1_due_date + 4.days,
                            {})

    relation = FactoryBot.build_stubbed(:hierarchy_relation,
                                        from: parent_following_work_package1,
                                        to: sibling)

    allow(sibling)
      .to receive(:parent_relation)
            .and_return relation

    sibling
  end

  subject { instance.call(attributes) }

  before do
    following.each do |wp, results|
      allow(WorkPackage)
        .to receive(:hierarchy_tree_following)
              .with(wp)
              .and_return(results)

      allow(results)
        .to receive(:includes)
              .and_return(results)
    end
  end
  let(:attributes) { [:start_date] }

  shared_examples_for 'reschedules' do
    before do
      subject
    end

    it 'is success' do
      expect(subject)
        .to be_success
    end

    it 'updates the following work packages' do
      expected.each do |wp, (start_date, due_date)|
        expect(wp.start_date)
          .to eql start_date
        expect(wp.due_date)
          .to eql due_date
      end
    end

    it 'returns only the original and the changed work packages' do
      expected_to_change = if defined?(unchanged)
        expected.keys - unchanged
      else
        expected.keys
      end

      expected_to_change << work_package

      expect(subject.all_results)
        .to match_array expected_to_change
    end
  end

  context 'without relation' do
    it 'is success' do
      expect(subject)
        .to be_success
    end
  end

  context 'with a single successor' do
    let(:following) do
      {
        [work_package] => [following_work_package1],
        [following_work_package1] => []
      }
    end

    before do
      following_work_package1
    end

    context 'moving forward' do
      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.day] }
        end
      end

      context 'when the follower has no due date' do
        before do
          following_work_package1.due_date = nil
        end

        it_behaves_like 'reschedules' do
          let(:expected) do
            { following_work_package1 => [Date.today + 6.days, nil] }
          end
        end
      end
    end

    context 'moving forward with the follower having some space left' do
      let(:follower1_start_date) { Date.today + 3.day }
      let(:follower1_due_date) { Date.today + 5.day }

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.day] }
        end
      end
    end

    context 'moving forward with the follower having enough space left to not be moved at all' do
      let(:follower1_start_date) { Date.today + 10.day }
      let(:follower1_due_date) { Date.today + 12.day }

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [follower1_start_date, follower1_due_date] }
        end
        let(:unchanged) do
          [following_work_package1]
        end
      end
    end

    context 'moving forward with the follower having some space left and a delay' do
      let(:follower1_start_date) { Date.today + 5.day }
      let(:follower1_due_date) { Date.today + 7.day }
      let(:follower1_delay) { 3 }

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 9.days, Date.today + 11.day] }
        end
      end
    end

    context 'moving forward with the follower not needing to be moved' do
      let(:follower1_start_date) { Date.today + 6.day }
      let(:follower1_due_date) { Date.today + 8.day }

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.day] }
        end
        let(:unchanged) do
          [following_work_package1]
        end
      end
    end

    context 'moving backwards' do
      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.day] }
        end
      end
    end

    context 'moving backwards with space between' do
      let(:follower1_start_date) { Date.today + 3.day }
      let(:follower1_due_date) { Date.today + 5.day }

      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 2.days, Date.today] }
        end
      end
    end

    context 'moving backwards with the follower having another relation limiting movement' do
      let(:other_work_package) do
        FactoryBot.build_stubbed(:stubbed_work_package,
                                 type: type,
                                 start_date: follower1_start_date - 8.days,
                                 due_date: follower1_start_date - 5.days)
      end

      let(:follow_relation) do
        FactoryBot.build_stubbed(:follows_relation,
                                 to: work_package,
                                 from: following_work_package1)
      end

      let(:other_follow_relation) do
        FactoryBot.build_stubbed(:follows_relation,
                                 delay: 3,
                                 to: other_work_package,
                                 from: following_work_package1)
      end

      before do
        allow(following_work_package1)
          .to receive(:follows_relations)
                .and_return [other_follow_relation, follow_relation]

        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today, Date.today + 2.days],
            other_work_package => [follower1_start_date - 8.days, follower1_start_date - 5.days] }
        end
        let(:unchanged) do
          [other_work_package]
        end
      end
    end

    context 'removing the dates on the predecessor' do
      before do
        work_package.start_date = work_package.due_date = nil
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [follower1_start_date, follower1_due_date] }
        end
        let(:unchanged) do
          [following_work_package1]
        end
      end
    end

    context 'not moving and the successor not having start & due date (e.g. creating relation)' do
      let(:follower1_start_date) { nil }
      let(:follower1_due_date) { nil }

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 1.day] }
        end
      end
    end

    context 'not moving and the successor having start before predecessor due date (e.g. creating relation)' do
      let(:follower1_start_date) { work_package_due_date - 5.days }
      let(:follower1_due_date) { nil }

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 1.day] }
        end
      end
    end

    context 'not moving and the successor having start and due before predecessor due date (e.g. creating relation)' do
      let(:follower1_start_date) { work_package_due_date - 5.days }
      let(:follower1_due_date) { work_package_due_date - 2.days }

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 4.day] }
        end
      end
    end

    context 'not having dates and the successor not having start & due date (e.g. creating relation)' do
      let(:work_package_due_date) { nil }
      let(:follower1_start_date) { nil }
      let(:follower1_due_date) { nil }

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [nil, nil] }
        end
        let(:unchanged) do
          [following_work_package1]
        end
      end
    end

    context 'with the successor having another predecessor which has no dates' do
      let(:following_work_package1) do
        stub_follower(follower1_start_date,
                      follower1_due_date,
                      work_package => follower1_delay,
                      another_successor => 0)
      end
      let(:another_successor) do
        FactoryBot.build_stubbed(:stubbed_work_package,
                                 start_date: nil,
                                 due_date: nil)
      end

      context 'moving forward' do
        before do
          work_package.due_date = Date.today + 5.days
        end

        it_behaves_like 'reschedules' do
          let(:expected) do
            { following_work_package1 => [Date.today + 6.days, Date.today + 8.day] }
          end
        end
      end

      context 'moving backwards' do
        before do
          work_package.due_date = Date.today - 5.days
        end

        it_behaves_like 'reschedules' do
          let(:expected) do
            { following_work_package1 => [Date.today - 4.days, Date.today - 2.day] }
          end
        end
      end
    end
  end

  context 'with only a parent' do
    let(:parent_work_package) do
      FactoryBot.build_stubbed(:stubbed_work_package)
    end
    let(:work_package_start_date) { Date.today - 5.days }
    let(:following) do
      {
        [work_package] => [parent_work_package],
        [parent_work_package] => []
      }
    end

    before do
      work_package.parent = parent_work_package
      allow(parent_work_package)
        .to receive(:descendants)
              .and_return([work_package])
      work_package.build_parent_relation from_id: parent_work_package.id
    end

    it_behaves_like 'reschedules' do
      let(:expected) do
        { parent_work_package => [work_package_start_date, work_package_due_date] }
      end
    end
  end

  context 'with a single successor having a parent' do
    let(:following) do
      {
        [work_package] => [following_work_package1,
                           parent_following_work_package1],
        [following_work_package1,
         parent_following_work_package1] => []
      }
    end

    before do
      following_work_package1
      parent_following_work_package1
    end

    context 'moving forward' do
      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            parent_following_work_package1 => [Date.today + 6.days, Date.today + 8.days] }
        end
      end
    end

    context 'moving forward with the parent having another child not being moved' do
      let(:parent_follower1_start_date) { follower1_start_date }
      let(:parent_follower1_due_date) { follower1_due_date + 4.days }

      let(:following) do
        {
          [work_package] => [following_work_package1,
                             parent_following_work_package1,
                             follower_sibling_work_package],
          [following_work_package1,
           parent_following_work_package1] => []
        }
      end

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            parent_following_work_package1 => [Date.today + 5.days, Date.today + 8.days],
            follower_sibling_work_package => [follower1_due_date + 2.days, follower1_due_date + 4.days] }
        end
        let(:unchanged) do
          [follower_sibling_work_package]
        end
      end
    end

    context 'moving backwards' do
      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            parent_following_work_package1 => [Date.today - 4.days, Date.today - 2.days] }
        end
      end
    end

    context 'moving backwards with the parent having another relation limiting movement' do
      let(:other_work_package) do
        FactoryBot.build_stubbed(:stubbed_work_package,
                                 type: type,
                                 start_date: Date.today - 8.days,
                                 due_date: Date.today - 4.days)
      end

      let(:other_follow_relation) do
        FactoryBot.build_stubbed(:follows_relation,
                                 delay: 2,
                                 to: other_work_package,
                                 from: parent_following_work_package1)
      end

      before do
        allow(parent_following_work_package1)
          .to receive(:follows_relations)
                .and_return [other_follow_relation]

        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 1.day, Date.today + 1.day],
            parent_following_work_package1 => [Date.today - 1.day, Date.today + 1.day],
            other_work_package => [Date.today - 8.days, Date.today - 4.days] }
        end
        let(:unchanged) do
          [other_work_package]
        end
      end
    end

    context 'moving backwards with the parent having another relation not limiting movement' do
      let(:other_work_package) do
        FactoryBot.build_stubbed(:stubbed_work_package,
                                 type: type,
                                 start_date: Date.today - 10.days,
                                 due_date: Date.today - 9.days)
      end

      let(:other_follow_relation) do
        FactoryBot.build_stubbed(:follows_relation,
                                 delay: 2,
                                 to: other_work_package,
                                 from: parent_following_work_package1)
      end

      before do
        allow(parent_following_work_package1)
          .to receive(:follows_relations)
                .and_return [other_follow_relation]

        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            parent_following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            other_work_package => [Date.today - 10.days, Date.today - 9.days] }
        end
        let(:unchanged) do
          [other_work_package]
        end
      end
    end

    context 'moving backwards with the parent having another child not being moved' do
      let(:parent_follower1_start_date) { follower1_start_date }
      let(:parent_follower1_due_date) { follower1_due_date + 4.days }

      let(:following) do
        {
          [work_package] => [following_work_package1,
                             parent_following_work_package1,
                             follower_sibling_work_package],
          [following_work_package1,
           parent_following_work_package1] => []
        }
      end

      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            parent_following_work_package1 => [Date.today - 4.days, Date.today + 7.days],
            follower_sibling_work_package => [follower1_due_date + 2.days, follower1_due_date + 4.days] }
        end
        let(:unchanged) do
          [follower_sibling_work_package]
        end
      end
    end
  end

  context 'with a single successor having a child' do
    let(:child_start_date) { follower1_start_date }
    let(:child_due_date) { follower1_due_date }

    let(:child_work_package) { stub_follower_child(following_work_package1, child_start_date, child_due_date) }

    let(:following) do
      {
        [work_package] => [following_work_package1,
                           child_work_package],
        [following_work_package1,
         child_work_package] => []
      }
    end

    before do
      following_work_package1
      child_work_package
    end

    context 'moving forward' do
      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            child_work_package => [Date.today + 6.days, Date.today + 8.days] }
        end
      end
    end
  end

  context 'with a single successor having two children' do
    let(:follower1_start_date) { work_package_due_date + 1.day }
    let(:follower1_due_date) { work_package_due_date + 10.days }
    let(:child1_start_date) { follower1_start_date }
    let(:child1_due_date) { follower1_start_date + 3.days }
    let(:child2_start_date) { follower1_start_date + 8.days }
    let(:child2_due_date) { follower1_due_date }

    let(:child1_work_package) { stub_follower_child(following_work_package1, child1_start_date, child1_due_date) }
    let(:child2_work_package) { stub_follower_child(following_work_package1, child2_start_date, child2_due_date) }

    let(:following) do
      {
        [work_package] => [following_work_package1,
                           child1_work_package,
                           child2_work_package],
        [following_work_package1,
         child1_work_package,
         child2_work_package] => []
      }
    end

    before do
      following_work_package1
      child1_work_package
      child2_work_package
    end

    context 'unchanged dates (e.g. when creating a follows relation) and successor starting 1 day after scheduled' do
      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [follower1_start_date, follower1_due_date],
            child1_work_package => [child1_start_date, child1_due_date],
            child2_work_package => [child2_start_date, child2_due_date] }
        end
        let(:unchanged) do
          [following_work_package1, child1_work_package, child2_work_package]
        end
      end
    end

    context 'unchanged dates (e.g. when creating a follows relation) and successor starting 3 days after scheduled' do
      let(:follower1_start_date) { work_package_due_date + 3.days }
      let(:follower1_due_date) { follower1_start_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 6.days }
      let(:child2_start_date) { follower1_start_date + 8.days }
      let(:child2_due_date) { follower1_due_date }

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [follower1_start_date, follower1_due_date],
            child1_work_package => [child1_start_date, child1_due_date],
            child2_work_package => [child2_start_date, child2_due_date] }
        end
        let(:unchanged) do
          [following_work_package1, child1_work_package, child2_work_package]
        end
      end
    end

    context 'unchanged dates (e.g. when creating a follows relation) and successor\'s first child' do
      let(:follower1_start_date) { work_package_due_date - 3.days }
      let(:follower1_due_date) { work_package_due_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 6.days }
      let(:child2_start_date) { follower1_start_date + 8.days }
      let(:child2_due_date) { follower1_due_date }

      # following parent is reduced in length as the children allow to be executed at the same time
      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [work_package_due_date + 1.day, follower1_due_date],
            child1_work_package => [work_package_due_date + 1.day, follower1_start_date + 10.days],
            child2_work_package => [child2_start_date, child2_due_date] }
        end
        let(:unchanged) do
          [child2_work_package]
        end
      end
    end

    context 'unchanged dates (e.g. when creating a follows relation) and successor\s children need to be rescheduled' do
      let(:follower1_start_date) { work_package_due_date - 8.days }
      let(:follower1_due_date) { work_package_due_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 4.days }
      let(:child2_start_date) { follower1_start_date + 6.days }
      let(:child2_due_date) { follower1_due_date }

      # following parent is reduced in length and children are rescheduled
      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [work_package_due_date + 1.day, follower1_start_date + 21.days],
            child1_work_package => [work_package_due_date + 1.day, child1_due_date + 9.days],
            child2_work_package => [work_package_due_date + 1.day, follower1_start_date + 21.days] }
        end
      end
    end
  end

  context 'with a chain of successors' do
    let(:follower1_start_date) { Date.today + 1.day }
    let(:follower1_due_date) { Date.today + 3.day }
    let(:follower2_start_date) { Date.today + 4.day }
    let(:follower2_due_date) { Date.today + 8.day }
    let(:follower3_start_date) { Date.today + 9.day }
    let(:follower3_due_date) { Date.today + 10.day }

    let(:following) do
      {
        [work_package] => [following_work_package1,
                           following_work_package2,
                           following_work_package3],
        [following_work_package1,
         following_work_package2,
         following_work_package3] => []
      }
    end

    before do
      following_work_package1
      following_work_package2
      following_work_package3
    end

    context 'moving forward' do
      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            following_work_package2 => [Date.today + 9.days, Date.today + 13.days],
            following_work_package3 => [Date.today + 14.days, Date.today + 15.days] }
        end
      end
    end

    context 'moving forward with some space between the followers' do
      let(:follower1_start_date) { Date.today + 1.day }
      let(:follower1_due_date) { Date.today + 3.day }
      let(:follower2_start_date) { Date.today + 7.day }
      let(:follower2_due_date) { Date.today + 10.day }
      let(:follower3_start_date) { Date.today + 17.day }
      let(:follower3_due_date) { Date.today + 18.day }

      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            following_work_package2 => [Date.today + 9.days, Date.today + 12.days],
            following_work_package3 => [Date.today + 17.days, Date.today + 18.days] }
        end
        let(:unchanged) do
          [following_work_package3]
        end
      end
    end

    context 'moving backwards' do
      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            following_work_package2 => [Date.today - 1.days, Date.today + 3.days],
            following_work_package3 => [Date.today + 4.days, Date.today + 5.days] }
        end
      end
    end
  end

  context 'with a chain of successors with two paths leading to the same work package in the end' do
    let(:follower3_start_date) { Date.today + 4.day }
    let(:follower3_due_date) { Date.today + 7.day }
    let(:follower3_delay) { 0 }
    let(:following_work_package3) do
      stub_follower(follower3_start_date,
                    follower3_due_date,
                    work_package => follower3_delay)
    end
    let(:follower4_start_date) { Date.today + 9.days }
    let(:follower4_due_date) { Date.today + 10.days }
    let(:follower4_delay_2) { 0 }
    let(:follower4_delay_3) { 0 }
    let(:following_work_package4) do
      stub_follower(follower4_start_date,
                    follower4_due_date,
                    following_work_package2 => follower4_delay_2,
                    following_work_package3 => follower4_delay_3)
    end
    let(:following) do
      {
        [work_package] => [following_work_package1,
                           following_work_package2,
                           following_work_package3,
                           following_work_package4],
        [following_work_package1,
         following_work_package2,
         following_work_package3,
         following_work_package4] => []
      }
    end

    before do
      following_work_package1
      following_work_package2
      following_work_package3
      following_work_package4
    end

    context 'moving forward' do
      before do
        work_package.due_date = Date.today + 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today + 6.days, Date.today + 8.days],
            following_work_package2 => [Date.today + 9.days, Date.today + 13.days],
            following_work_package3 => [Date.today + 6.days, Date.today + 9.days],
            following_work_package4 => [Date.today + 14.days, Date.today + 15.days] }
        end
      end
    end

    context 'moving backwards' do
      before do
        work_package.due_date = Date.today - 5.days
      end

      it_behaves_like 'reschedules' do
        let(:expected) do
          { following_work_package1 => [Date.today - 4.days, Date.today - 2.days],
            following_work_package2 => [Date.today - 1.days, Date.today + 3.days],
            following_work_package3 => [Date.today - 1.days, Date.today + 2.days],
            following_work_package4 => [Date.today + 4.days, Date.today + 5.days] }
        end
      end
    end
  end

  context 'when setting the parent' do
    let(:new_parent_work_package) { FactoryBot.build_stubbed(:stubbed_work_package) }
    let(:attributes) { [:parent] }

    before do
      allow(new_parent_work_package)
        .to receive(:soonest_start)
              .and_return(soonest_date)
      allow(work_package)
        .to receive(:parent)
              .and_return(new_parent_work_package)
    end

    context "with the parent being restricted in it's ability to be moved" do
      let(:soonest_date) { Date.today + 3.days }

      it 'sets the start date to the earliest possible date' do
        subject

        expect(work_package.start_date).to eql(Date.today + 3.days)
      end
    end

    context 'with the parent being restricted but work package already having dates set' do
      let(:soonest_date) { Date.today + 3.days }

      before do
        work_package.start_date = Date.today + 4.days
        work_package.due_date = Date.today + 5.days
      end

      it 'sets the dates to provided dates' do
        subject

        expect(work_package.start_date).to eql(Date.today + 4.days)
        expect(work_package.due_date).to eql(Date.today + 5.days)
      end
    end

    context 'with the parent being restricted but the attributes define an earlier date' do
      let(:soonest_date) { Date.today + 3.days }

      before do
        work_package.start_date = Date.today + 1.days
        work_package.due_date = Date.today + 2.days
      end

      # This would be invalid but the dates should be set nevertheless
      # so we can have a correct error handling.
      it 'sets the dates to provided dates' do
        subject

        expect(work_package.start_date).to eql(Date.today + 1.days)
        expect(work_package.due_date).to eql(Date.today + 2.days)
      end
    end
  end
end
