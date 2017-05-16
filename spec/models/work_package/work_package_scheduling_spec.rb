#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  describe '#overdue' do
    let(:work_package) do
      FactoryGirl.create(:work_package,
                         due_date: due_date)
    end

    shared_examples_for 'overdue' do
      subject { work_package.overdue? }

      it { is_expected.to be_truthy }
    end

    shared_examples_for 'on time' do
      subject { work_package.overdue? }

      it { is_expected.to be_falsey }
    end

    context 'one day ago' do
      let(:due_date) { 1.day.ago.to_date }

      it_behaves_like 'overdue'
    end

    context 'today' do
      let(:due_date) { Date.today.to_date }

      it_behaves_like 'on time'
    end

    context 'next day' do
      let(:due_date) { 1.day.from_now.to_date }

      it_behaves_like 'on time'
    end

    context 'no due date' do
      let(:due_date) { nil }

      it_behaves_like 'on time'
    end

    context 'status closed' do
      let(:due_date) { 1.day.ago.to_date }
      let(:status) do
        FactoryGirl.create(:status,
                           is_closed: true)
      end

      before do
        work_package.status = status
      end

      it_behaves_like 'on time'
    end
  end

  describe '#behind_schedule?' do
    let(:work_package) do
      FactoryGirl.create(:work_package,
                         start_date: start_date,
                         due_date: due_date,
                         done_ratio: done_ratio)
    end

    shared_examples_for 'behind schedule' do
      subject { work_package.behind_schedule? }

      it { is_expected.to be_truthy }
    end

    shared_examples_for 'in schedule' do
      subject { work_package.behind_schedule? }

      it { is_expected.to be_falsey }
    end

    context 'no start date' do
      let(:start_date) { nil }
      let(:due_date) { 1.day.from_now.to_date }
      let(:done_ratio) { 0 }

      it_behaves_like 'in schedule'
    end

    context 'no end date' do
      let(:start_date) { 1.day.from_now.to_date }
      let(:due_date) { nil }
      let(:done_ratio) { 0 }

      it_behaves_like 'in schedule'
    end

    context "more done than it's calendar time" do
      let(:start_date) { 50.day.ago.to_date }
      let(:due_date) { 50.day.from_now.to_date }
      let(:done_ratio) { 90 }

      it_behaves_like 'in schedule'
    end

    context 'not started' do
      let(:start_date) { 1.day.ago.to_date }
      let(:due_date) { 1.day.from_now.to_date }
      let(:done_ratio) { 0 }

      it_behaves_like 'behind schedule'
    end

    context "more done than it's calendar time" do
      let(:start_date) { 100.day.ago.to_date }
      let(:due_date) { Date.today }
      let(:done_ratio) { 90 }

      it_behaves_like 'behind schedule'
    end
  end

  describe 'rescheduling' do
    let(:work_package1_start) { Date.today }
    let(:work_package1_due) { Date.today + 3 }
    let(:work_package1) do
      FactoryGirl.create(:work_package,
                         start_date: work_package1_start,
                         due_date: work_package1_due)
    end
    let(:work_package2_start) { nil }
    let(:work_package2_due) { nil }
    let(:work_package2) do
      FactoryGirl.create(:work_package,
                         start_date: work_package2_start,
                         due_date: work_package2_due)
    end

    shared_examples_for 'scheduled work package' do
      before do
        work_package2.reload
      end

      it 'start_date' do
        expect(work_package2.start_date).to eql expected_start
      end

      it 'due_date' do
        expect(work_package2.due_date).to eql expected_due
      end
    end

    context 'for preceds/follows relationships' do
      let(:delay) { 0 }
      let(:follows_relation) do
        FactoryGirl.create(:relation,
                           relation_type: Relation::TYPE_PRECEDES,
                           from: work_package1,
                           to: work_package2,
                           delay: delay)
      end

      before do
        follows_relation
      end

      context 'upon relationship generation' do
        context 'when the following work package has no dates set' do
          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package1_due + 1 }
            let(:expected_due) { work_package1_due + 1 }
          end

          context 'when a delay is set' do
            let(:delay) { 3 }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package1_due + delay + 1 }
              let(:expected_due) { work_package1_due + delay + 1 }
            end
          end
        end

        context 'when the following work package has the start date set' do
          context 'when that date is behind the preceding due date' do
            let(:work_package2_start) { work_package1_due + 4 }

            it_behaves_like 'scheduled work package' do
              # not rescheduled
              let(:expected_start) { work_package2_start }
              let(:expected_due) { nil }
            end

            context 'when a delay is set and is small enough to fit' do
              let(:delay) { 3 }

              it_behaves_like 'scheduled work package' do
                # not rescheduled
                let(:expected_start) { work_package2_start }
                let(:expected_due) { nil }
              end
            end

            context 'when a delay is set that is to big to fit' do
              let(:delay) { 6 }

              it_behaves_like 'scheduled work package' do
                let(:expected_start) { work_package1_due + delay + 1 }
                let(:expected_due) { work_package1_due + delay + 1 }
              end
            end
          end

          context 'when that date is before the preceding due date' do
            let(:work_package2_start) { work_package1_due - 2 }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package1_due + 1 }
              let(:expected_due) { work_package1_due + 1 }
            end

            context 'when a delay is set' do
              let(:delay) { 2 }

              it_behaves_like 'scheduled work package' do
                let(:expected_start) { work_package1_due + delay + 1 }
                let(:expected_due) { work_package1_due + delay + 1 }
              end
            end
          end
        end

        context 'when the following work package has the due date set' do
          context 'when that date is behind the preceding due date' do
            let(:work_package2_due) { work_package1_due + 2 }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package1_due + 1 }
              let(:expected_due) { work_package1_due + 1 }
            end

            context 'when a delay is set and is small enough to fit' do
              let(:delay) { 3 }

              it_behaves_like 'scheduled work package' do
                let(:expected_start) { work_package1_due + delay + 1 }
                let(:expected_due) { work_package1_due + delay + 1 }
              end
            end

            context 'when a delay is set that is to big to fit' do
              let(:delay) { 6 }

              it_behaves_like 'scheduled work package' do
                let(:expected_start) { work_package1_due + delay + 1 }
                let(:expected_due) { work_package1_due + delay + 1 }
              end
            end
          end

          context 'when that date is before the preceding due date' do
            let(:work_package2_due) { work_package1_due - 2 }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package1_due + 1 }
              let(:expected_due) { work_package1_due + 1 }
            end

            context 'when a delay is set' do
              let(:delay) { 2 }

              it_behaves_like 'scheduled work package' do
                let(:expected_start) { work_package1_due + delay + 1 }
                let(:expected_due) { work_package1_due + delay + 1 }
              end
            end
          end
        end

        context 'when the preceding work package has only the start date set' do
          let(:work_package1_due) { nil }

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package1_start + 1 }
            let(:expected_due) { work_package1_start + 1 }
          end
        end

        context 'when the preceding work package has no dates set' do
          let(:work_package1_start) { nil }
          let(:work_package1_due) { nil }

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { nil }
            let(:expected_due) { nil }
          end
        end
      end

      context 'upon preceding work package due date update' do
        let(:work_package2_start) { work_package1_due + 2 }
        let(:work_package2_due) { work_package1_due + 5 }

        before do
          work_package1.reload
          work_package2.reload
        end

        context 'when the date is moved forward into the following work package dates' do
          let(:new_work_package1_due) { work_package2.start_date + 1 }

          before do
            work_package1.due_date = new_work_package1_due
            work_package1.save!
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { new_work_package1_due + 1 }
            let(:expected_due) { new_work_package1_due + 4 }
          end
        end

        context 'when the date is moved forward but not inside the following work package dates' do
          let(:new_work_package1_due) { work_package1_due + 1 }

          before do
            work_package1.due_date = new_work_package1_due
            work_package1.save!
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end
        end

        context 'when the date is moved backwards' do
          let(:move_by) { -1 }
          let(:new_work_package1_due) { work_package1_due + move_by }

          before do
            work_package1.due_date = new_work_package1_due
            work_package1.save!
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start + move_by }
            let(:expected_due) { work_package2_due + move_by }
          end
        end

        context 'when the due date is removed' do
          let(:new_work_package1_due) { nil }

          before do
            work_package1.due_date = new_work_package1_due
            work_package1.save!
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end
        end

        context 'when there is another work package also preceding the wp' do
          let(:work_package3) do
            FactoryGirl.create(:work_package,
                               start_date: work_package1_start,
                               due_date: work_package1_due)
          end
          let(:follows_relation2) do
            FactoryGirl.create(:relation,
                               relation_type: Relation::TYPE_PRECEDES,
                               from: work_package3,
                               to: work_package2)
          end

          before do
            follows_relation2
          end

          context 'when the date is moved backwards' do
            let(:move_by) { -3 }
            let(:new_work_package1_due) { work_package1_due + move_by }

            before do
              work_package1.due_date = new_work_package1_due
              work_package1.save!
            end

            it_behaves_like 'scheduled work package' do
              # moved backwards as much as possible
              let(:expected_start) { work_package3.due_date + delay + 1 }
              let(:expected_due) do
                work_package3.due_date + delay + 1 +
                  (work_package3.due_date - work_package3.start_date)
              end
            end
          end
        end
      end

      context 'upon preceding work package start date update' do
        let(:work_package2_start) { work_package1_due + 2 }
        let(:work_package2_due) { work_package1_due + 5 }

        context 'when moving backwards' do
          let(:new_work_package1_start) { work_package1_start - 6 }

          before do
            work_package1.start_date = new_work_package1_start
            work_package1.save
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end

          context 'when the preceding work package has no due date set' do
            let(:work_package2_start) { work_package1_start + 2 }
            let(:work_package2_due) { work_package1_start + 5 }
            let(:work_package1_due) { nil }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package2_start - 6 }
              let(:expected_due) { work_package2_due - 6 }
            end
          end
        end

        context 'when moving forward' do
          let(:new_work_package1_start) { work_package1_start + 6 }

          before do
            work_package1.start_date = new_work_package1_start
            work_package1.save
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end

          context 'when the preceding work package has no due date set' do
            let(:work_package2_start) { work_package1_start + 2 }
            let(:work_package2_due) { work_package1_start + 5 }
            let(:work_package1_due) { nil }

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package2_start + delay + 5 }
              let(:expected_due) { work_package2_due + delay + 5 }
            end
          end
        end
      end

      context 'upon removing the start and due date of the preceding work package' do
        let(:work_package2_start) { work_package1_due + 2 }
        let(:work_package2_due) { work_package1_due + 5 }

        before do
          work_package1.reload
          work_package2.reload

          work_package1.start_date, work_package1.due_date = nil
          work_package1.save!
        end

        it_behaves_like 'scheduled work package' do
          let(:expected_start) { work_package2_start }
          let(:expected_due) { work_package2_due }
        end
      end

      context 'upon removing the start and due date of the following work package' do
        let(:work_package2_start) { work_package1_due + 2 }
        let(:work_package2_due) { work_package1_due + 5 }

        before do
          work_package1.reload
          work_package2.reload

          work_package2.start_date, work_package2.due_date = nil
          work_package2.save!
        end

        it_behaves_like 'scheduled work package' do
          let(:expected_start) { nil }
          let(:expected_due) { nil }
        end
      end

      context 'upon moving the following work package inside the preceding work package dates' do
        let(:work_package2_start) { work_package1_due + 2 }
        let(:work_package2_due) { work_package1_due + 5 }

        before do
          work_package1.reload
          work_package2.reload

          work_package2.start_date = work_package1_start
        end

        it 'should be invalid' do
          expect(work_package2).to be_invalid
        end
      end

      context 'upon updating the delay' do
        let(:delay) { 5 }
        let(:work_package2_start) { work_package1_due + 6 }
        let(:work_package2_due) { work_package1_due + 8 }

        before do
          work_package1.reload
          work_package2.reload
        end

        context 'when increasing the delay' do
          let(:new_delay) { 7 }

          before do
            follows_relation.delay = new_delay
            follows_relation.save!
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package1_due + new_delay + 1 }
            let(:expected_due) { work_package1_due + new_delay + 3 }
          end
        end

        context 'when reducing the delay' do
          let(:new_delay) { 3 }

          before do
            follows_relation.delay = new_delay
            follows_relation.save!
          end

          it_behaves_like 'scheduled work package' do
            # not changed
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end
        end
      end
    end

    [Relation::TYPE_BLOCKS,
     Relation::TYPE_DUPLICATES,
     Relation::TYPE_RELATES].each do |relation_type|
      context "for #{relation_type} relationships" do
        let(:blocks_relation) do
          FactoryGirl.create(:relation,
                             relation_type: relation_type,
                             from: work_package1,
                             to: work_package2)
        end

        context 'upon relationship generation' do
          before do
            blocks_relation
          end

          it_behaves_like 'scheduled work package' do
            let(:expected_start) { work_package2_start }
            let(:expected_due) { work_package2_due }
          end
        end

        context 'when updating the due date of the blocking work package' do
          let(:work_package2_start) { work_package1_due + 1 }
          let(:work_package2_due) { work_package1_due + 5 }

          before do
            blocks_relation
          end

          context 'forwards' do
            before do
              work_package1.due_date += 5
              work_package1.save
            end

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package2_start }
              let(:expected_due) { work_package2_due }
            end
          end

          context 'backwards' do
            before do
              work_package1.start_date -= 5
              work_package1.due_date -= 5
              work_package1.save
            end

            it_behaves_like 'scheduled work package' do
              let(:expected_start) { work_package2_start }
              let(:expected_due) { work_package2_due }
            end
          end
        end
      end
    end
  end
end
