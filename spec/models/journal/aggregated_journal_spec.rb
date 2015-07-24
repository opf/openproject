#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++require 'rspec'

require 'spec_helper'

describe AggregatedJournal, type: :model do
  let(:journal_a) do
    FactoryGirl.build(:journal,
                      journable_id: 5,
                      id: 5,
                      created_at: Time.now,
                      notes: 'Some random note')
  end

  context 'invalid constructor arguments' do
    let(:journal_b) { FactoryGirl.build(:journal, journable_id: journal_a.journable_id + 5) }

    it 'should throw for invalid arguments' do
      expect { AggregatedJournal.new(journal_a, journal_b) }.to raise_error(ArgumentError)
    end
  end

  context 'valid constructor arguments' do
    context 'artificial arguments' do
      let(:journal_b) do
        FactoryGirl.build(
          :journal,
          journable_id: journal_a.journable_id,
          id: journal_a.id + 1,
          user_id: journal_a.user_id,
          created_at: journal_a.created_at + 0.5 * JournalAggregator::MAX_TEMPORAL_DISTANCE,
          activity_type: 'work_packages')
      end

      it 'aggregates attributes from both journals' do
        aggregated_journal = AggregatedJournal.new(journal_a, journal_b)
        expect(aggregated_journal.journaled_attributes).to include(
           activity_type: 'work_packages',
           notes: 'Some random note')
      end
    end
  end
end
