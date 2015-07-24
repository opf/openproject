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

describe JournalAggregator do
  let(:user) { FactoryGirl.build(:user) }
  let(:journal_a) do
    FactoryGirl.build(:journal,
                      journable_id: 5,
                      user_id: user,
                      id: 5,
                      notes: 'Please note:',
                      created_at: Time.now)
  end

  shared_examples_for 'does merge' do
    it 'should merge' do
      expect(JournalAggregator.are_mergeable?(journal_a, journal_b)).to be_truthy
    end
  end

  shared_examples_for 'does not merge' do
    it 'should merge' do
      expect(JournalAggregator.are_mergeable?(journal_a, journal_b)).to be_falsey
    end
  end

  describe '#are_mergeable?' do
    context 'equal journals' do
      it_behaves_like 'does merge' do
        let(:journal_b) { journal_a }
      end
    end

    context 'differing journable_id' do
      let(:journal_b) { FactoryGirl.build(:journal, journable_id: journal_a.journable_id + 5) }

      it_behaves_like 'does not merge'
    end

    context 'differing author' do
      let(:another_user) { FactoryGirl.build(:user) }
      let(:journal_b) { FactoryGirl.build(:journal, user_id: another_user) }

     it_behaves_like 'does not merge'
    end

    context 'discontinuous ids' do
      let(:journal_b) { FactoryGirl.build(:journal, id: journal_a.id + 2) }

      it_behaves_like 'does not merge'
    end

    context 'two comments' do
      let(:journal_b) { FactoryGirl.build(:journal, notes: 'I am a different note') }

      it_behaves_like 'does not merge'
    end

    context 'too much time between journals' do
      let(:journal_b) do
        FactoryGirl.build(
          :journal,
          created_at: journal_a.created_at + 2 * JournalAggregator::MAX_TEMPORAL_DISTANCE)
      end

      it_behaves_like 'does not merge'
    end

    context 'two mergeable journals' do
      let(:journal_b) do
        FactoryGirl.build(
          :journal,
          journable_id: journal_a.journable_id,
          user_id: journal_a.user_id,
          id: journal_a.id + 1,
          created_at: journal_a.created_at + 0.5 * JournalAggregator::MAX_TEMPORAL_DISTANCE
        )
      end

      it_behaves_like 'does merge'
    end
  end
end
