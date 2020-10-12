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
#++require 'rspec'

require 'spec_helper'

RSpec::Matchers.define :be_equivalent_to_journal do |expected|
  ignored_attributes = [:notes_id, :notes_version]

  match do |actual|
    expected_attributes = get_normalized_attributes expected
    actual_attributes = get_normalized_attributes actual

    expected_attributes.except(*ignored_attributes) == actual_attributes.except(*ignored_attributes)
  end

  failure_message do |actual|
    expected_attributes = get_normalized_attributes expected
    actual_attributes = actual.attributes.symbolize_keys
    ["expected attributes: #{display_sorted_hash(expected_attributes.except(*ignored_attributes))}",
     "actual attributes:   #{display_sorted_hash(actual_attributes.except(*ignored_attributes))}"]
      .join($/)
  end

  def get_normalized_attributes(journal)
    result = journal.attributes.symbolize_keys
    if result[:created_at]
      # µs are not stored in all DBMS
      result[:created_at] = result[:created_at].change(usec: 0)
    end

    result
  end

  def display_sorted_hash(hash)
    '{ ' + hash.sort.map { |k, v| "#{k.inspect}=>#{v.inspect}" }.join(', ') + ' }'
  end
end

describe Journal::AggregatedJournal, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) do
    FactoryBot.build(:work_package, project: project)
  end
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:initial_author) { user1 }

  subject { described_class.aggregated_journals }

  before do
    login_as(initial_author)
    work_package.save!
  end

  it 'returns the one and only journal' do
    expect(subject.count).to eql 1
    expect(subject.first).to be_equivalent_to_journal work_package.journals.first
  end

  it 'also indicates its ID via notes_id' do
    expect(subject.first.notes_id).to eql work_package.journals.first.id
  end

  it 'is the initial journal' do
    expect(subject.first.initial?).to be_truthy
  end

  it 'has no successor' do
    expect(subject.first.successor).to be_nil
  end

  it 'forwards project to the journable' do
    expect(subject.first.project).to eq(work_package.project)
  end

  context 'WP updated immediately after uncommented change' do
    let(:notes) { nil }

    before do
      changes = { status: FactoryBot.build(:status) }
      changes[:journal_notes] = notes if notes

      allow(User).to receive(:current).and_return(new_author)

      work_package.attributes = changes
      work_package.save!
    end

    context 'by author of last change' do
      let(:new_author) { initial_author }

      it 'returns a single aggregated journal' do
        expect(subject.count).to eql 1
        expect(subject.first).to be_equivalent_to_journal work_package.journals.second
      end

      it 'is the initial journal' do
        expect(subject.first.initial?).to be_truthy
      end

      it 'has no successor' do
        expect(subject.first.successor).to be_nil
      end

      it 'returns the single journal for both original journals' do
        expect(described_class.containing_journal work_package.journals.first)
          .to be_equivalent_to_journal subject.first

        expect(described_class.containing_journal work_package.journals.second)
          .to be_equivalent_to_journal subject.first
      end

      context 'with a comment' do
        let(:notes) { 'This is why I changed it.' }

        it 'returns a single aggregated journal' do
          expect(subject.count).to eql 1
          expect(subject.first).to be_equivalent_to_journal work_package.journals.second
        end

        context 'adding a second comment' do
          let(:notes) { 'Another comment, unrelated to the first one.' }

          before do
            work_package.add_journal(new_author, notes)
            work_package.save!
          end

          it 'returns two journals' do
            expect(subject.count).to eql 2
            expect(subject.first).to be_equivalent_to_journal work_package.journals.second
            expect(subject.second).to be_equivalent_to_journal work_package.journals.last
          end

          it 'has one initial journal and one non-initial journal' do
            expect(subject.first.initial?).to be_truthy
            expect(subject.second.initial?).to be_falsey
          end

          it 'has the first as predecessor of the second journal' do
            expect(subject.second.predecessor).to be_equivalent_to_journal subject.first
          end

          it 'has the second as successor of the first journal' do
            expect(subject.first.successor).to be_equivalent_to_journal subject.second
          end

          it 'returns the same aggregated journal for the first two originals' do
            expect(described_class.containing_journal work_package.journals.first)
              .to be_equivalent_to_journal subject.first

            expect(described_class.containing_journal work_package.journals.second)
              .to be_equivalent_to_journal subject.first
          end

          it 'returns a different aggregated journal for the last original' do
            expect(described_class.containing_journal work_package.journals.last)
              .to be_equivalent_to_journal subject.second
          end
        end

        context 'adding another change without comment' do
          before do
            work_package.reload # need to update the lock_version, avoiding StaleObjectError
            changes = { subject: 'foo' }

            work_package.attributes = changes
            work_package.save!
          end

          it 'returns a single journal' do
            expect(subject.count).to eql 1
          end

          it 'combines the notes of the earlier journal with attributes of the later journal' do
            expected_journal = work_package.journals.last
            expected_journal.notes = work_package.journals.second.notes

            expect(subject.first).to be_equivalent_to_journal expected_journal
          end

          it 'indicates the ID of the earlier journal via notes_id' do
            expect(subject.first.notes_id).to eql work_package.journals.second.id
          end

          it 'is the initial journal' do
            expect(subject.first.initial?).to be_truthy
          end

          it 'has no predecessor' do
            expect(subject.first.predecessor).to be_nil
          end

          it 'has no successor' do
            expect(subject.first.successor).to be_nil
          end
        end
      end
    end

    context 'by a different author' do
      let(:new_author) { user2 }

      it 'returns both journals' do
        expect(subject.count).to eql 2
        expect(subject.first).to be_equivalent_to_journal work_package.journals.first
        expect(subject.second).to be_equivalent_to_journal work_package.journals.second
      end

      it 'has the first as predecessor of the second journal' do
        expect(subject.second.predecessor).to be_equivalent_to_journal subject.first
      end
    end
  end

  context 'WP updated after aggregation timeout expired' do
    let(:delay) { (Setting.journal_aggregation_time_minutes.to_i + 1).minutes }

    before do
      work_package.status = FactoryBot.build(:status)
      work_package.save!
      second_journal = work_package.journals.second
      second_journal.update_column(:created_at, second_journal.created_at + delay)
    end

    it 'returns both journals' do
      expect(subject.count).to eql 2
      expect(subject.first).to be_equivalent_to_journal work_package.journals.first
      expect(subject.second).to be_equivalent_to_journal work_package.journals.second
    end
  end

  context 'aggregation is disabled' do
    before do
      allow(Setting).to receive(:journal_aggregation_time_minutes).and_return(0)
    end

    context 'WP updated within milliseconds' do
      let(:delay) { 0.001.seconds }

      before do
        work_package.status = FactoryBot.build(:status)
        work_package.save!
        work_package.journals.second.created_at = work_package.journals.first.created_at + delay
        work_package.journals.second.save!
      end

      it 'returns both journals' do
        expect(subject.count).to eql 2
        expect(subject.first).to be_equivalent_to_journal work_package.journals.first
        expect(subject.second).to be_equivalent_to_journal work_package.journals.second
      end
    end
  end

  context 'different WP updated immediately after change' do
    let(:other_wp) { FactoryBot.build(:work_package) }
    let(:delay) { 0.001.seconds }

    before do
      other_wp.save!
      # The delay is necessary to ensure the correct order of the journals.
      # Otherwise travis would create two journals with the exact same timestamp
      # resulting in a somewhere random ordering.
      other_wp.journals.first.created_at = work_package.journals.first.created_at + delay
      other_wp.journals.first.save!
    end

    it 'returns both journals' do
      expect(subject.count).to eql 2
      expect(subject.first).to be_equivalent_to_journal work_package.journals.first
      expect(subject.second).to be_equivalent_to_journal other_wp.journals.first
    end
  end

  context 'passing a journable as parameter' do
    subject { described_class.aggregated_journals(journable: work_package) }
    let(:other_wp) { FactoryBot.build(:work_package) }
    let(:new_author) { initial_author }

    before do
      other_wp.save!

      changes = { subject: 'a new subject!' }

      work_package.attributes = changes
      work_package.save!
    end

    it 'only returns the journals for the requested work package' do
      expect(subject.count).to eq 1
      expect(subject.first).to be_equivalent_to_journal work_package.journals.last
    end

    context 'specifying a maximum version' do
      subject do
        described_class.aggregated_journals(journable: work_package, until_version: version)
      end

      context 'equal to the latest version' do
        let(:version) { work_package.journals.last.version }

        it 'returns the same as for no specified version' do
          expect(subject.count).to eq 1
          expect(subject.first).to be_equivalent_to_journal work_package.journals.last
        end
      end

      context 'equal to the first version' do
        let(:version) { work_package.journals.first.version }

        it 'does not aggregate the second journal' do
          expect(subject.count).to eq 1
          expect(subject.first).to be_equivalent_to_journal work_package.journals.first
        end
      end
    end
  end

  context 'passing a filtering sql' do
    let!(:other_work_package) { FactoryBot.create(:work_package) }
    let(:sql) do
      <<~SQL
        SELECT journals.*
        FROM journals
        JOIN work_package_journals
          ON work_package_journals.journal_id = journals.id
          AND work_package_journals.project_id = #{project.id}
      SQL
    end
    subject { described_class.aggregated_journals(sql: sql) }

    it 'returns the journal of the work package in the project filtered for' do
      expect(subject.count).to eql 1
      expect(subject.first).to be_equivalent_to_journal work_package.journals.first
    end

    context 'with a sql filtering out every journal' do
      let(:sql) do
        <<~SQL
          SELECT journals.*
          FROM journals
          JOIN work_package_journals
            ON work_package_journals.journal_id = journals.id
            AND work_package_journals.project_id = #{project.id}
          WHERE journals.created_at < '#{Date.yesterday}'
        SQL
      end

      it 'returns no journal' do
        expect(subject.count).to eql 0
      end
    end

    context 'with a sql filtering out the first journal and having 3 journals' do
      let(:sql) do
        <<~SQL
          SELECT journals.*
          FROM journals
          JOIN work_package_journals
            ON work_package_journals.journal_id = journals.id
          WHERE journals.version > 1
        SQL
      end

      context 'with the first of the remaining journals having a comment' do
        before do
          other_work_package.add_journal(initial_author, 'some other notes')
          other_work_package.save!
          work_package.add_journal(initial_author, 'some notes')
          work_package.save!
          work_package.subject = 'A new subject'
          work_package.save!
        end

        it 'returns one journal per work package' do
          expect(subject.count).to eql 2
        end
      end
    end

    context 'with an sql filtering for both projects' do
      let(:sql) do
        <<~SQL
          SELECT journals.*
          FROM journals
          JOIN work_package_journals
            ON work_package_journals.journal_id = journals.id
            AND work_package_journals.project_id IN (#{project.id}, #{other_work_package.project_id})
        SQL
      end

      it 'returns no journal' do
        expect(subject.count).to eql 2
        expect(subject.first).to be_equivalent_to_journal work_package.journals.first
        expect(subject.last).to be_equivalent_to_journal other_work_package.journals.first
      end
    end
  end
end
