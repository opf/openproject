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
require Rails.root.join("db/migrate/20230608151123_add_validity_period_to_journals.rb")

RSpec.describe AddValidityPeriodToJournals, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject do
    ActiveRecord::Migration.suppress_messages do
      described_class
        .new
        .tap { _1.migrate(:down) }
        .tap { _1.migrate(:up) }
    end
  end

  let(:zero_time) { 30.minutes.ago }
  let(:initial_journal_time) { zero_time }                   # Created with the work package -> No conflicts
  let(:second_journal_time) { zero_time + 1.minute }         # Created one minute later      -> Conflicts with 3
  let(:third_journal_time) { zero_time + 1.minute }          # Created one minute later      -> Conflicts with 2
  let(:fourth_journal_time) { zero_time + 2.minutes }        # Created two minutes later     -> Conflicts with 5, 6 and 7
  let(:fourth_journal_update_time) { zero_time + 3.minutes } # Updated three minute later    -> Not relevant for this migration
  let(:fifth_journal_time) { zero_time + 2.minutes }         # Created two minutes later     -> Conflicts with 4, 6 and 7
  let(:sixth_journal_time) { zero_time + 2.minutes }         # Created two minutes later     -> Conflicts with 5, 5 and 7
  let(:seventh_journal_time) { zero_time + 2.minutes }       # Created two minutes later     -> Conflicts with 4, 5 and 6

  let(:work_package) do
    create(:work_package) do
      Journal.destroy_all
    end
  end

  let(:user) { create(:user) }

  let!(:initial_journal) do
    create(:work_package_journal,
           version: 1,
           user:,
           created_at: initial_journal_time,
           updated_at: initial_journal_time,
           validity_period: zero_time...zero_time + 1.minute,
           journable: work_package).reload
  end
  let!(:second_journal) do
    create(:work_package_journal,
           version: 2,
           user:,
           created_at: second_journal_time,
           updated_at: second_journal_time,
           validity_period: zero_time + 2.minutes...zero_time + 3.minutes,
           journable: work_package).reload
  end
  let!(:third_journal) do
    create(:work_package_journal,
           version: 3,
           user:,
           created_at: third_journal_time,
           updated_at: third_journal_time,
           validity_period: zero_time + 4.minutes...zero_time + 5.minutes,
           journable: work_package).reload
  end
  let!(:fourth_journal) do
    create(:work_package_journal,
           version: 4,
           user:,
           created_at: fourth_journal_time,
           updated_at: fourth_journal_update_time,
           validity_period: zero_time + 6.minutes...zero_time + 7.minutes,
           journable: work_package).reload
  end
  let!(:fifth_journal) do
    create(:work_package_journal,
           version: 5,
           user:,
           created_at: fifth_journal_time,
           updated_at: fifth_journal_time,
           validity_period: zero_time + 8.minutes...zero_time + 9.minutes,
           journable: work_package).reload
  end
  let!(:sixth_journal) do
    create(:work_package_journal,
           version: 6,
           user:,
           created_at: sixth_journal_time,
           updated_at: sixth_journal_time,
           validity_period: zero_time + 10.minutes...zero_time + 11.minutes,
           journable: work_package).reload
  end
  let!(:seventh_journal) do
    create(:work_package_journal,
           version: 7,
           user:,
           created_at: seventh_journal_time,
           updated_at: seventh_journal_time,
           validity_period: zero_time + 11.minutes...zero_time + 12.minutes,
           journable: work_package).reload
  end

  it "resets the overlapping journals", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    subject

    initial_journal.reload
    second_journal.reload
    third_journal.reload
    fourth_journal.reload
    fifth_journal.reload
    sixth_journal.reload
    seventh_journal.reload

    expect(initial_journal.created_at).to eql initial_journal_time
    expect(initial_journal.updated_at).to eql initial_journal_time
    expect(initial_journal.validity_period.begin).to eql initial_journal_time
    expect(initial_journal.validity_period.end.strftime("%s%L").to_i).to eql second_journal_time.strftime("%s%L").to_i - 1

    expect(second_journal.created_at.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i - 1
    expect(second_journal.updated_at.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i - 1
    expect(second_journal.validity_period.begin.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i - 1
    expect(second_journal.validity_period.end.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i

    expect(third_journal.created_at.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i
    expect(third_journal.updated_at.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i
    expect(third_journal.validity_period.begin.strftime("%s%L").to_i).to eql third_journal_time.strftime("%s%L").to_i
    # Since the fourth journal had to be moved 3 times (by 3 ms in total) to avoid conflicts with its subsequent 3 journals,
    # the validity period ends at the old fourth journal time minus 3 ms.
    expect(third_journal.validity_period.end.strftime("%s%L").to_i).to eql fourth_journal_time.strftime("%s%L").to_i - 3

    # The fourth journal had to be moved 3 times to avoid conflicts with its subsequent 3 journals.
    # All timestamps had to be moved by 1 ms each time.
    expect(fourth_journal.created_at.strftime("%s%L").to_i).to eql fourth_journal_time.strftime("%s%L").to_i - 3
    # This time is not updated at all. It already had a different time than the created_at.
    # It now overlaps with the fifth, sixth and seventh journal. This can happen and is okay.
    # It might e.g. be, that the comment on the journal was updated.
    expect(fourth_journal.updated_at.strftime("%s%L").to_i).to eql fourth_journal_update_time.strftime("%s%L").to_i
    expect(fourth_journal.validity_period.begin.strftime("%s%L").to_i).to eql fourth_journal_time.strftime("%s%L").to_i - 3
    expect(fourth_journal.validity_period.end.strftime("%s%L").to_i).to eql fifth_journal_time.strftime("%s%L").to_i - 2

    # The fifth journal had to be moved 2 times to avoid conflicts with its subsequent 2 journals.
    # All timestamps had to be moved by 1 ms each time.
    expect(fifth_journal.created_at.strftime("%s%L").to_i).to eql fifth_journal_time.strftime("%s%L").to_i - 2
    expect(fifth_journal.updated_at.strftime("%s%L").to_i).to eql fifth_journal_time.strftime("%s%L").to_i - 2
    expect(fifth_journal.validity_period.begin.strftime("%s%L").to_i).to eql fifth_journal_time.strftime("%s%L").to_i - 2
    expect(fifth_journal.validity_period.end.strftime("%s%L").to_i).to eql sixth_journal_time.strftime("%s%L").to_i - 1

    # The sixth journal had to be moved 1 times to avoid conflicts with its subsequent 1 journals.
    # All timestamps had to be moved by 1 ms.
    expect(sixth_journal.created_at.strftime("%s%L").to_i).to eql sixth_journal_time.strftime("%s%L").to_i - 1
    expect(sixth_journal.updated_at.strftime("%s%L").to_i).to eql sixth_journal_time.strftime("%s%L").to_i - 1
    expect(sixth_journal.validity_period.begin.strftime("%s%L").to_i).to eql sixth_journal_time.strftime("%s%L").to_i - 1
    expect(sixth_journal.validity_period.end.strftime("%s%L").to_i).to eql seventh_journal_time.strftime("%s%L").to_i

    # The seventh journal is the last in the list of conflicting journals so it itself had not to be moved.
    expect(seventh_journal.created_at.strftime("%s%L").to_i).to eql seventh_journal_time.strftime("%s%L").to_i
    expect(seventh_journal.updated_at.strftime("%s%L").to_i).to eql seventh_journal_time.strftime("%s%L").to_i
    expect(seventh_journal.validity_period.begin.strftime("%s%L").to_i).to eql seventh_journal_time.strftime("%s%L").to_i
    # Since it is the currently last journal, it's range is open-ended.
    expect(seventh_journal.validity_period.end).to be_nil
  end
end
