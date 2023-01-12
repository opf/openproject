#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe WorkPackages::ApplyWorkingDaysChangeJob do
  create_shared_association_defaults_for_work_package_factory

  subject(:job) { described_class }

  shared_let(:user) { create(:user) }
  shared_let(:next_monday) { Date.current.next_occurring(:monday) }
  shared_let(:monday) { Date.current.monday }

  let(:work_week) { week_with_saturday_and_sunday_as_weekend }
  # This must run before any working days are changed, hence the `let!` form
  let!(:previous_working_days) { work_week }
  let!(:previous_non_working_days) { [] }

  shared_examples_for 'journal updates with note' do
    let(:changed_work_packages) { [] }
    let(:unchanged_work_packages) { [] }
    let(:journal_notice) { raise 'need to specify note' }

    it 'adds journal entries to changed work packages' do
      subject

      changed_work_packages.each do |work_package|
        expect(work_package.journals.count)
          .to eq 2
        expect(work_package.journals.last.notes)
          .to include(journal_notice)
      end

      unchanged_work_packages.each do |work_package|
        expect(work_package.journals.count)
          .to eq 1
      end
    end
  end

  describe '#perform' do
    subject { job.perform_now(user_id: user.id, previous_working_days:, previous_non_working_days:) }

    context 'with non-working weekday settings' do
      context 'when a work package includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days                  | MTWTFSS |
          work_package          | XXXX ░░ |
          work_package_on_start |   XX ░░ |
          work_package_on_due   | XXX  ░░ |
          wp_start_only         |   [  ░░ |
          wp_due_only           |   ]  ░░ |
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'moves the finish date to the corresponding number of now-excluded days to maintain duration [#31992]' do
          subject

          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days                  | MTWTFSS |
            work_package          | XX▓XX░░ |
            work_package_on_start |   ░XX░░ |
            work_package_on_due   | XX▓X ░░ |
            wp_start_only         |   ░[ ░░ |
            wp_due_only           |   ░] ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package,
             work_package_on_start,
             work_package_on_due,
             wp_start_only,
             wp_due_only]
          end
          let(:journal_notice) { "**Working days** changed (Wednesday is now non-working)." }
        end
      end

      context 'when a work package was scheduled to start on a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |   XX ░░ |
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'moves the start date to the earliest working day in the future, ' \
           'and the finish date changes by consequence [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package |   ░XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) { "**Working days** changed (Wednesday is now non-working)." }
        end
      end

      context 'when a work package includes a date that is no more a non-working day' do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        before do
          set_working_week_days('saturday')
        end

        it 'moves the finish date backwards to the corresponding number of now-included days to maintain duration [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days          | fssMTWTFSS |
            work_package  | XX▓X     ░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) { "**Working days** changed (Saturday is now working)." }
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  XX  ░░ | working days work week
          follower    |    XXX░ | working days include weekends, follows predecessor
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'moves the follower start date by consequence of the predecessor dates shift [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |  X▓X ░░ |
            follower    |   ░ XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor, follower]
          end
          let(:journal_notice) { "**Working days** changed (Wednesday is now non-working)." }
        end
      end

      context 'when a follower has a predecessor with delay covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | XX   ░░ |
          follower    |    X ░░ | follows predecessor with delay 1
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'moves the follower start date forward to keep the delay to 1 day' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX░  ░░ |
            follower    |   ░ X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [follower]
          end
          let(:unchanged_work_packages) do
            [predecessor]
          end
          let(:journal_notice) { "**Working days** changed (Wednesday is now non-working)." }
        end
      end

      context 'with work packages without dates following each other with delay' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |      ░░ |
          follower    |      ░░ | follows predecessor with delay 5
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'does not move anything (obviously) and does not crash either' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |   ░  ░░ |
            follower    |   ░  ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with delay covering multiple days with different working changes' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | X ░  ░░ |
          follower    |   ░ X░░ | follows predecessor with delay 2
        CHART
        let(:work_week) { set_work_week('monday', 'tuesday', 'thursday', 'friday') }

        before do
          set_non_working_week_days('tuesday')
          set_working_week_days('wednesday')
        end

        it 'correctly handles the changes' do
          subject
          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor | X░   ░░ |
            follower    |  ░  X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  X▓X ░░ | working days work week
          follower    |   ░ XXX | working days include weekends, follows predecessor
        CHART
        let(:work_week) { set_work_week('monday', 'tuesday', 'thursday', 'friday') }

        before do
          set_working_week_days('wednesday')
        end

        it 'does not move the follower backwards' do
          subject

          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor |  XX  ░░ |
            follower    |     XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor]
          end
          let(:unchanged_work_packages) do
            [follower]
          end
          let(:journal_notice) { "**Working days** changed (Wednesday is now working)." }
        end
      end

      context 'when a follower has a predecessor with a non-working day between them that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS  |
          predecessor | XX░  ░░  |
          follower    |   ░XX░░  | follows predecessor
        CHART
        let(:work_week) { set_work_week('monday', 'tuesday', 'thursday', 'friday') }

        before do
          set_working_week_days('wednesday')
        end

        it 'does not move the follower' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX      |
            follower    |    XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a work package has working days include weekends, and includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | XXXX ░░ | working days include weekends
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'does not move any dates' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package | XXXX ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when a work package only has a duration' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |      ░░ | duration 3 days
        CHART

        before do
          set_non_working_week_days('wednesday')
        end

        it 'does not change anything' do
          subject
          expect(work_package.duration).to eq(3)
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming non working days' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |    X ░░   | follows wp3
          wp3  | XXX  ░░   |
        CHART

        before do
          set_non_working_week_days('tuesday', 'wednesday', 'friday')
        end

        it 'updates them only once most of the time' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  |
            wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (Tuesday is now non-working, Wednesday is now non-working, Friday is now non-working)."
          end
        end
      end

      context 'with multiple predecessors for same follower' do
        # Given below schedule, as work packages are processed by order of start_date
        # ascending, the processing order will be wp1, wp2, wp3.
        #
        # So when Tuesday, Wednesday and Friday become non-working days:
        # * wp1 will move from Tuesday to Thursday and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled and moves to next Monday
        # * wp2 will move from Wednesday-Thursday to Thursday-nextMonday too and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled *again* and moves to next Thursday
        let_schedule(<<~CHART)
          days | MTWTFSS |
          wp1  |  X   ░░ |
          wp2  |   XX ░░ |
          wp3  |     X░░ | follows wp1, follows wp2
        CHART

        before do
          set_non_working_week_days('tuesday', 'wednesday', 'friday')
        end

        it 'can update some followers twice sometimes' do
          expect { subject }
            .to change { WorkPackage.order(:subject).pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 2])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwt |
            wp1  |  ░░X░░░ ░░  |
            wp2  |  ░░X▓▓▓X░░  |
            wp3  |  ░░ ░░░ ░░X |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (Tuesday is now non-working, Wednesday is now non-working, Friday is now non-working)."
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming working days' do
        let_schedule(<<~CHART)
          days | MTWTFSSmtwtfssmtwtfss  |
          wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X | follows wp2
          wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  | follows wp3
          wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
        CHART

        let(:work_week) { set_work_week('monday', 'thursday') }

        before do
          set_working_week_days('tuesday', 'wednesday', 'friday')
        end

        it 'keeps the same start dates and updates them only once' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |      ░░     ░░XXX  ░░  | follows wp2
            wp2  |      ░░   X ░░     ░░  | follows wp3
            wp3  | XXX  ░░     ░░     ░░  |
          CHART
          expect(WorkPackage.pluck(:lock_version)).to all(be <= 1)
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp3]
          end
          let(:unchanged_work_packages) do
            [wp2]
          end
          let(:journal_notice) do
            "**Working days** changed (Tuesday is now working, Wednesday is now working, Friday is now working)."
          end
        end
      end

      context 'when having multiple work packages following each other and first one only has a due date' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |   XX ░░   | follows wp3
          wp3  |  ]   ░░   |
        CHART

        before do
          set_non_working_week_days('tuesday', 'wednesday', 'friday')
        end

        it 'updates all of them correctly' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSm  t ssm  t ssm |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░X▓▓X░░░ ░░ ░░░  |
            wp3  |  ░░]░░░ ░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (Tuesday is now non-working, Wednesday is now non-working, Friday is now non-working)."
          end
        end
      end

      context 'when having a non english default language', with_settings: { default_language: :fr } do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        before do
          set_working_week_days('saturday')
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            I18n.with_locale(:fr) do
              I18n.t(:'working_days.journal_note.changed',
                     changes: I18n.t(:'working_days.journal_note.days.working',
                                     day: I18n.t('date.day_names')[6]))
            end
          end
        end
      end

      context 'when turning Sunday into a working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSSm |
          work_package  |     X▓▓X |
        CHART

        before do
          set_working_week_days('Sunday')
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            "**Working days** changed (Sunday is now working)."
          end
        end
      end
    end

    context 'with non-working days' do
      let(:work_week) { week_with_all_days_working }
      let!(:previous_non_working_days) { week_with_saturday_and_sunday_as_non_working_day }

      context 'when a work package includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days                  | MTWTFSS |
          work_package          | XXXX ░░ |
          work_package_on_start |   XX ░░ |
          work_package_on_due   | XXX  ░░ |
          wp_start_only         |   [  ░░ |
          wp_due_only           |   ]  ░░ |
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the finish date to the corresponding number of now-excluded days to maintain duration [#31992]' do
          subject

          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days                  | MTWTFSS |
            work_package          | XX▓XX░░ |
            work_package_on_start |   ░XX░░ |
            work_package_on_due   | XX▓X ░░ |
            wp_start_only         |   ░[ ░░ |
            wp_due_only           |   ░] ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package,
             work_package_on_start,
             work_package_on_due,
             wp_start_only,
             wp_due_only]
          end
          let(:journal_notice) do
            "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)."
          end
        end
      end

      context 'when a work package was scheduled to start on a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |   XX ░░ |
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the start date to the earliest working day in the future, ' \
           'and the finish date changes by consequence [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package |   ░XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)."
          end
        end
      end

      context 'when a work package includes a date that is no more a non-working day' do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        before do
          set_working_days(monday.next_occurring(:saturday))
        end

        it 'moves the finish date backwards to the corresponding number of now-included days to maintain duration [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days          | fssMTWTFSS |
            work_package  | XX▓X     ░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end

          let(:journal_notice) do
            "**Working days** changed (#{monday.next_occurring(:saturday)} is now working)."
          end
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  XX  ░░ | working days work week
          follower    |    XXX░ | working days include weekends, follows predecessor
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the follower start date by consequence of the predecessor dates shift [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |  X▓X ░░ |
            follower    |   ░ XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor, follower]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)." }
        end
      end

      context 'when a follower has a predecessor with delay covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | XX   ░░ |
          follower    |    X ░░ | follows predecessor with delay 1
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the follower start date forward to keep the delay to 1 day' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX░  ░░ |
            follower    |   ░ X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [follower]
          end
          let(:unchanged_work_packages) do
            [predecessor]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)." }
        end
      end

      context 'with work packages without dates following each other with delay' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |      ░░ |
          follower    |      ░░ | follows predecessor with delay 5
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not move anything (obviously) and does not crash either' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |   ░  ░░ |
            follower    |   ░  ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with delay covering multiple days with different working changes' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | X ░  ░░ |
          follower    |   ░ X░░ | follows predecessor with delay 2
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }

        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_non_working_days(next_monday.next_occurring(:tuesday))
          set_working_days(non_working_day.date)
        end

        it 'correctly handles the changes' do
          subject
          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor | X░   ░░ |
            follower    |  ░  X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  X▓X ░░ | working days work week
          follower    |   ░ XXX | working days include weekends, follows predecessor
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_working_days(non_working_day.date)
        end

        it 'does not move the follower backwards' do
          subject

          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor |  XX  ░░ |
            follower    |     XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor]
          end
          let(:unchanged_work_packages) do
            [follower]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now working)." }
        end
      end

      context 'when a follower has a predecessor with a non-working day between them that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS  |
          predecessor | XX░  ░░  |
          follower    |   ░XX░░  | follows predecessor
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_working_days(non_working_day.date)
        end

        it 'does not move the follower' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX      |
            follower    |    XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a work package has working days include weekends, and includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | XXXX ░░ | working days include weekends
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not move any dates' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package | XXXX ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when a work package only has a duration' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |      ░░ | duration 3 days
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not change anything' do
          subject
          expect(work_package.duration).to eq(3)
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming non working days' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |    X ░░   | follows wp3
          wp3  | XXX  ░░   |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'updates them only once most of the time' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  |
            wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'with multiple predecessors for same follower' do
        # Given below schedule, as work packages are processed by order of start_date
        # ascending, the processing order will be wp1, wp2, wp3.
        #
        # So when Tuesday, Wednesday and Friday become non-working days:
        # * wp1 will move from Tuesday to Thursday and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled and moves to next Monday
        # * wp2 will move from Wednesday-Thursday to Thursday-nextMonday too and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled *again* and moves to next Thursday
        let_schedule(<<~CHART)
          days | MTWTFSS |
          wp1  |  X   ░░ |
          wp2  |   XX ░░ |
          wp3  |     X░░ | follows wp1, follows wp2
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'can update some followers twice sometimes' do
          expect { subject }
            .to change { WorkPackage.order(:subject).pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 2])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwt |
            wp1  |  ░░X░░░ ░░  |
            wp2  |  ░░X▓▓▓X░░  |
            wp3  |  ░░ ░░░ ░░X |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming working days' do
        let_schedule(<<~CHART)
          days | MTWTFSSmtwtfssmtwtfss  |
          wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X | follows wp2
          wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  | follows wp3
          wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day +
          set_non_working_days(*non_working_days).pluck(:date)
        end

        before do
          set_working_days(*non_working_days)
        end

        it 'keeps the same start dates and updates them only once' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |      ░░     ░░XXX  ░░  | follows wp2
            wp2  |      ░░   X ░░     ░░  | follows wp3
            wp3  | XXX  ░░     ░░     ░░  |
          CHART
          expect(WorkPackage.pluck(:lock_version)).to all(be <= 1)
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp3]
          end
          let(:unchanged_work_packages) do
            [wp2]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now working" }.join(', ')})."
          end
        end
      end

      context 'when having multiple work packages following each other and first one only has a due date' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |   XX ░░   | follows wp3
          wp3  |  ]   ░░   |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'updates all of them correctly' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSm  t ssm  t ssm |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░X▓▓X░░░ ░░ ░░░  |
            wp3  |  ░░]░░░ ░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'when having a non english default language', with_settings: { default_language: :fr } do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        let(:non_working_days) do
          [monday.next_occurring(:saturday), next_monday.next_occurring(:saturday)]
        end

        before do
          # Make 'saturday' a working day
          set_working_days(*non_working_days)
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            I18n.with_locale(:fr) do
              I18n.t(:'working_days.journal_note.changed',
                     changes: non_working_days.map do |date|
                       I18n.t(:'working_days.journal_note.dates.working', date:)
                     end.join(", "))
            end
          end
        end
      end

      context 'when turning Sunday into a working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSSm |
          work_package  |     X▓▓X |
        CHART

        let(:non_working_days) do
          [monday.next_occurring(:sunday), next_monday.next_occurring(:sunday)]
        end

        before do
          # Make 'sunday' a working weekday
          set_working_days(*non_working_days)
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            I18n.t(:'working_days.journal_note.changed',
                   changes: non_working_days.map do |date|
                     I18n.t(:'working_days.journal_note.dates.working', date:)
                   end.join(", "))
          end
        end
      end
    end

    context 'with non-working days and non-working weekday settings' do
      # The non working weekday settings are set in the beginning of the file
      # Leaving them as is, we get a mix of non-working days and weekday settings.

      context 'when a work package includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days                  | MTWTFSS |
          work_package          | XXXX ░░ |
          work_package_on_start |   XX ░░ |
          work_package_on_due   | XXX  ░░ |
          wp_start_only         |   [  ░░ |
          wp_due_only           |   ]  ░░ |
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the finish date to the corresponding number of now-excluded days to maintain duration [#31992]' do
          subject

          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days                  | MTWTFSS |
            work_package          | XX▓XX░░ |
            work_package_on_start |   ░XX░░ |
            work_package_on_due   | XX▓X ░░ |
            wp_start_only         |   ░[ ░░ |
            wp_due_only           |   ░] ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package,
             work_package_on_start,
             work_package_on_due,
             wp_start_only,
             wp_due_only]
          end
          let(:journal_notice) do
            "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)."
          end
        end
      end

      context 'when a work package was scheduled to start on a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |   XX ░░ |
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the start date to the earliest working day in the future, ' \
           'and the finish date changes by consequence [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package |   ░XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)."
          end
        end
      end

      context 'when a work package includes a date that is no more a non-working day' do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        let!(:previous_non_working_days) { week_with_saturday_and_sunday_as_non_working_day }

        before do
          set_working_days(monday.next_occurring(:saturday))
          set_working_week_days('saturday')
        end

        it 'moves the finish date backwards to the corresponding number of now-included days to maintain duration [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days          | fssMTWTFSS |
            work_package  | XX▓X     ░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end

          let(:journal_notice) do
            "**Working days** changed (Saturday is now working, #{monday.next_occurring(:saturday)} is now working)."
          end
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  XX  ░░ | working days work week
          follower    |    XXX░ | working days include weekends, follows predecessor
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the follower start date by consequence of the predecessor dates shift [#31992]' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |  X▓X ░░ |
            follower    |   ░ XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor, follower]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)." }
        end
      end

      context 'when a follower has a predecessor with delay covering a day that is now a non-working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | XX   ░░ |
          follower    |    X ░░ | follows predecessor with delay 1
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'moves the follower start date forward to keep the delay to 1 day' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX░  ░░ |
            follower    |   ░ X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [follower]
          end
          let(:unchanged_work_packages) do
            [predecessor]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now non-working)." }
        end
      end

      context 'with work packages without dates following each other with delay' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |      ░░ |
          follower    |      ░░ | follows predecessor with delay 5
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not move anything (obviously) and does not crash either' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor |   ░  ░░ |
            follower    |   ░  ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with delay covering multiple days with different working changes' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor | X ░  ░░ |
          follower    |   ░ X░░ | follows predecessor with delay 2
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }

        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_non_working_days(next_monday.next_occurring(:tuesday))
          set_working_days(non_working_day.date)
        end

        it 'correctly handles the changes' do
          subject
          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor | X░   ░░ |
            follower    |  ░  X░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a follower has a predecessor with dates covering a day that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS |
          predecessor |  X▓X ░░ | working days work week
          follower    |   ░ XXX | working days include weekends, follows predecessor
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_working_days(non_working_day.date)
        end

        it 'does not move the follower backwards' do
          subject

          expect_schedule(WorkPackage.all, <<~CHART)
            days        | MTWTFSS |
            predecessor |  XX  ░░ |
            follower    |     XXX |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [predecessor]
          end
          let(:unchanged_work_packages) do
            [follower]
          end
          let(:journal_notice) { "**Working days** changed (#{next_monday.next_occurring(:wednesday)} is now working)." }
        end
      end

      context 'when a follower has a predecessor with a non-working day between them that is now a working day' do
        let_schedule(<<~CHART)
          days        | MTWTFSS  |
          predecessor | XX░  ░░  |
          follower    |   ░XX░░  | follows predecessor
        CHART

        let(:non_working_day) { create(:non_working_day, date: next_monday.next_occurring(:wednesday)) }
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day + [non_working_day.date]
        end

        before do
          set_working_days(non_working_day.date)
        end

        it 'does not move the follower' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days        | MTWTFSS |
            predecessor | XX      |
            follower    |    XX░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [predecessor, follower]
          end
        end
      end

      context 'when a work package has working days include weekends, and includes a date that is now a non-working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | XXXX ░░ | working days include weekends
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not move any dates' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days         | MTWTFSS |
            work_package | XXXX ░░ |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when a work package only has a duration' do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |      ░░ | duration 3 days
        CHART

        before do
          set_non_working_days(next_monday.next_occurring(:wednesday))
        end

        it 'does not change anything' do
          subject
          expect(work_package.duration).to eq(3)
        end

        it_behaves_like 'journal updates with note' do
          let(:unchanged_work_packages) do
            [work_package]
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming non working days' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |    X ░░   | follows wp3
          wp3  | XXX  ░░   |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'updates them only once most of the time' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  |
            wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'with multiple predecessors for same follower' do
        # Given below schedule, as work packages are processed by order of start_date
        # ascending, the processing order will be wp1, wp2, wp3.
        #
        # So when Tuesday, Wednesday and Friday become non-working days:
        # * wp1 will move from Tuesday to Thursday and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled and moves to next Monday
        # * wp2 will move from Wednesday-Thursday to Thursday-nextMonday too and its followers will be rescheduled too
        #   * follower wp3 gets rescheduled *again* and moves to next Thursday
        let_schedule(<<~CHART)
          days | MTWTFSS |
          wp1  |  X   ░░ |
          wp2  |   XX ░░ |
          wp3  |     X░░ | follows wp1, follows wp2
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'can update some followers twice sometimes' do
          expect { subject }
            .to change { WorkPackage.order(:subject).pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 2])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwt |
            wp1  |  ░░X░░░ ░░  |
            wp2  |  ░░X▓▓▓X░░  |
            wp3  |  ░░ ░░░ ░░X |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'when having multiple work packages following each other, and having days becoming working days' do
        let_schedule(<<~CHART)
          days | MTWTFSSmtwtfssmtwtfss  |
          wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X | follows wp2
          wp2  |  ░░ ░░░ ░░X░░░ ░░ ░░░  | follows wp3
          wp3  | X▓▓X▓▓▓X░░ ░░░ ░░ ░░░  |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end
        let!(:previous_non_working_days) do
          week_with_saturday_and_sunday_as_non_working_day +
          set_non_working_days(*non_working_days).pluck(:date)
        end

        before do
          set_working_days(*non_working_days)
        end

        it 'keeps the same start dates and updates them only once' do
          subject
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSmtwtfssmtwtfss  |
            wp1  |      ░░     ░░XXX  ░░  | follows wp2
            wp2  |      ░░   X ░░     ░░  | follows wp3
            wp3  | XXX  ░░     ░░     ░░  |
          CHART
          expect(WorkPackage.pluck(:lock_version)).to all(be <= 1)
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp3]
          end
          let(:unchanged_work_packages) do
            [wp2]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now working" }.join(', ')})."
          end
        end
      end

      context 'when having multiple work packages following each other and first one only has a due date' do
        let_schedule(<<~CHART)
          days | MTWTFSS   |
          wp1  |     X▓▓XX | follows wp2
          wp2  |   XX ░░   | follows wp3
          wp3  |  ]   ░░   |
        CHART

        let(:non_working_days) do
          [
            next_monday.next_occurring(:tuesday), next_monday.next_occurring(:wednesday),
            next_monday.next_occurring(:friday), next_monday.next_occurring(:tuesday) + 1.week,
            next_monday.next_occurring(:wednesday) + 1.week, next_monday.next_occurring(:friday) + 1.week,
            next_monday.next_occurring(:tuesday) + 2.weeks, next_monday.next_occurring(:wednesday) + 2.weeks,
            next_monday.next_occurring(:friday) + 2.weeks
          ]
        end

        before do
          set_non_working_days(*non_working_days)
        end

        it 'updates all of them correctly' do
          expect { subject }
            .to change { WorkPackage.pluck(:lock_version) }
            .from([0, 0, 0])
            .to([1, 1, 1])
          expect(WorkPackage.all).to match_schedule(<<~CHART)
            days | MTWTFSSm  t ssm  t ssm |
            wp1  |  ░░ ░░░ ░░ ░░░X▓▓X▓▓▓X |
            wp2  |  ░░ ░░░X▓▓X░░░ ░░ ░░░  |
            wp3  |  ░░]░░░ ░░ ░░░ ░░ ░░░  |
          CHART
        end

        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [wp1, wp2, wp3]
          end
          let(:journal_notice) do
            "**Working days** changed (#{non_working_days.map { |day| "#{day} is now non-working" }.join(', ')})."
          end
        end
      end

      context 'when having a non english default language', with_settings: { default_language: :fr } do
        let_schedule(<<~CHART)
          days          | fssMTWTFSS |
          work_package  | X▓▓XX   ░░ |
        CHART

        let(:non_working_days) do
          [monday.next_occurring(:saturday), next_monday.next_occurring(:saturday)]
        end
        let!(:previous_non_working_days) { week_with_saturday_and_sunday_as_non_working_day }

        before do
          # Make 'saturday' a working day
          set_working_days(*non_working_days)
          set_working_week_days('saturday')
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            I18n.with_locale(:fr) do
              I18n.t(:'working_days.journal_note.changed',
                     changes: (
                       [
                         I18n.t(:'working_days.journal_note.days.working',
                                day: I18n.t('date.day_names')[6])
                       ] +
                       non_working_days.map do |date|
                         I18n.t(:'working_days.journal_note.dates.working', date:)
                       end
                     ).join(", "))
            end
          end
        end
      end

      context 'when turning Sunday into a working day' do
        let_schedule(<<~CHART)
          days          | MTWTFSSm |
          work_package  |     X▓▓X |
        CHART

        let!(:previous_non_working_days) { week_with_saturday_and_sunday_as_non_working_day }

        let(:non_working_days) do
          [monday.next_occurring(:sunday), next_monday.next_occurring(:sunday)]
        end

        before do
          # Make 'sunday' a working weekday and a remove it as a non-working day
          set_working_days(*non_working_days)
          set_working_week_days('sunday')
        end

        # Not interested in the scheduling changes in this spec
        it_behaves_like 'journal updates with note' do
          let(:changed_work_packages) do
            [work_package]
          end
          let(:journal_notice) do
            I18n.t(:'working_days.journal_note.changed',
                   changes: (
                     [
                       I18n.t(:'working_days.journal_note.days.working',
                              day: I18n.t('date.day_names')[0])
                     ] +
                     non_working_days.map do |date|
                       I18n.t(:'working_days.journal_note.dates.working', date:)
                     end
                   ).join(", "))
          end
        end
      end
    end
  end

  describe '.scheduled?' do
    context 'with a job already scheduled in the DB' do
      before do
        ActiveJob::QueueAdapters::DelayedJobAdapter
          .new
          .enqueue(described_class.new(user_id: 5, previous_non_working_days: [1, 2]))
      end

      it 'is true' do
        expect(described_class)
          .to be_scheduled
      end
    end

    context 'without a job already scheduled in the DB' do
      it 'is false' do
        expect(described_class)
          .not_to be_scheduled
      end
    end
  end
end
