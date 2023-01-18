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
require 'spec_helper'

describe Relation do
  create_shared_association_defaults_for_work_package_factory

  let(:from) { create(:work_package) }
  let(:to) { create(:work_package) }
  let(:type) { 'relates' }
  let(:relation) { build(:relation, from:, to:, relation_type: type) }

  describe 'all relation types' do
    Relation::TYPES.each do |key, type_hash|
      let(:type) { key }
      let(:reversed) { type_hash[:reverse] }

      before do
        relation.save!
      end

      it "sets the correct type for for '#{key}'" do
        if reversed.nil?
          expect(relation.relation_type).to eq(type)
        else
          expect(relation.relation_type).to eq(reversed)
        end
      end
    end
  end

  describe '#relation_type= / #relation_type' do
    let(:type) { Relation::TYPE_RELATES }

    it 'sets the type' do
      relation.relation_type = Relation::TYPE_BLOCKS
      expect(relation.relation_type).to eq(Relation::TYPE_BLOCKS)
    end
  end

  describe 'follows / precedes' do
    context 'for FOLLOWS' do
      let(:type) { Relation::TYPE_FOLLOWS }

      it 'is not reversed' do
        expect(relation.save).to be(true)
        relation.reload

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end

      it 'fails validation with invalid date and reverses' do
        relation.delay = 'xx'
        expect(relation).not_to be_valid
        expect(relation.save).to be(false)

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end
    end

    context 'for PRECEDES' do
      let(:type) { Relation::TYPE_PRECEDES }

      it 'is reversed' do
        expect(relation.save).to be(true)
        relation.reload

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.from).to eq(to)
        expect(relation.to).to eq(from)
      end
    end
  end

  describe '#follows?' do
    context 'for a follows relation' do
      let(:type) { Relation::TYPE_FOLLOWS }

      it 'is truthy' do
        expect(relation)
          .to be_follows
      end
    end

    context 'for a precedes relation' do
      let(:type) { Relation::TYPE_PRECEDES }

      it 'is truthy' do
        expect(relation)
          .to be_follows
      end
    end

    context 'for a blocks relation' do
      let(:type) { Relation::TYPE_BLOCKS }

      it 'is falsey' do
        expect(relation)
          .not_to be_follows
      end
    end
  end

  describe '#successor_soonest_start' do
    context 'with a follows relation' do
      let_schedule(<<~CHART)
        days     | MTWTFSS |
        main     | ]       |
        follower |         | follows main
      CHART

      it 'returns predecessor due_date + 1' do
        relation = schedule.follows_relation(from: 'follower', to: 'main')
        expect(relation.successor_soonest_start).to eq(schedule.tuesday)
      end
    end

    context 'with a follows relation with predecessor having only start date' do
      let_schedule(<<~CHART)
        days     | MTWTFSS |
        main     | [       |
        follower |         | follows main
      CHART

      it 'returns predecessor start_date + 1' do
        relation = schedule.follows_relation(from: 'follower', to: 'main')
        expect(relation.successor_soonest_start).to eq(schedule.tuesday)
      end
    end

    context 'with a non-follows relation' do
      let_schedule(<<~CHART)
        days    | MTWTFSS |
        main    | X       |
        related |         |
      CHART
      let(:relation) { create(:relation, from: main, to: related) }

      it 'returns nil' do
        expect(relation.successor_soonest_start).to be_nil
      end
    end

    context 'with a follows relation with a delay' do
      let_schedule(<<~CHART)
        days       | MTWTFSS |
        main       | X       |
        follower_a |         | follows main with delay 0
        follower_b |         | follows main with delay 1
        follower_c |         | follows main with delay 3
      CHART

      it 'returns predecessor due_date + delay + 1' do
        relation_a = schedule.follows_relation(from: 'follower_a', to: 'main')
        expect(relation_a.successor_soonest_start).to eq(schedule.tuesday)

        relation_b = schedule.follows_relation(from: 'follower_b', to: 'main')
        expect(relation_b.successor_soonest_start).to eq(schedule.wednesday)

        relation_c = schedule.follows_relation(from: 'follower_c', to: 'main')
        expect(relation_c.successor_soonest_start).to eq(schedule.friday)
      end
    end

    context 'with a follows relation with a delay and with non-working days in the delay period' do
      let_schedule(<<~CHART)
        days            | MTWTFSSmtw |
        main            | X░ ░ ░░ ░  |
        follower_delay0 |  ░ ░ ░░ ░  | follows main with delay 0
        follower_delay1 |  ░ ░ ░░ ░  | follows main with delay 1
        follower_delay2 |  ░ ░ ░░ ░  | follows main with delay 2
        follower_delay3 |  ░ ░ ░░ ░  | follows main with delay 3
      CHART

      it 'returns a date such as the number of working days between both work package is equal to the delay' do
        set_work_week('monday', 'wednesday', 'friday')

        relation_delay0 = schedule.follows_relation(from: 'follower_delay0', to: 'main')
        expect(relation_delay0.successor_soonest_start).to eq(schedule.wednesday)

        relation_delay1 = schedule.follows_relation(from: 'follower_delay1', to: 'main')
        expect(relation_delay1.successor_soonest_start).to eq(schedule.friday)

        relation_delay2 = schedule.follows_relation(from: 'follower_delay2', to: 'main')
        expect(relation_delay2.successor_soonest_start).to eq(schedule.monday + 7.days)

        relation_delay3 = schedule.follows_relation(from: 'follower_delay3', to: 'main')
        expect(relation_delay3.successor_soonest_start).to eq(schedule.wednesday + 7.days)
      end
    end

    context 'with a follows relation with a delay, non-working days, and follower ignoring non-working days' do
      let_schedule(<<~CHART)
        days            | MTWTFSSmtw |
        main            | X░ ░ ░░ ░  |
        follower_delay0 |  ░ ░ ░░ ░  | follows main with delay 0, working days include weekends
        follower_delay1 |  ░ ░ ░░ ░  | follows main with delay 1, working days include weekends
        follower_delay2 |  ░ ░ ░░ ░  | follows main with delay 2, working days include weekends
        follower_delay3 |  ░ ░ ░░ ░  | follows main with delay 3, working days include weekends
      CHART

      it 'returns predecessor due_date + delay + 1 (like without non-working days)' do
        set_work_week('monday', 'wednesday', 'friday')

        relation_delay0 = schedule.follows_relation(from: 'follower_delay0', to: 'main')
        expect(relation_delay0.successor_soonest_start).to eq(schedule.tuesday)

        relation_delay1 = schedule.follows_relation(from: 'follower_delay1', to: 'main')
        expect(relation_delay1.successor_soonest_start).to eq(schedule.wednesday)

        relation_delay2 = schedule.follows_relation(from: 'follower_delay2', to: 'main')
        expect(relation_delay2.successor_soonest_start).to eq(schedule.thursday)

        relation_delay3 = schedule.follows_relation(from: 'follower_delay3', to: 'main')
        expect(relation_delay3.successor_soonest_start).to eq(schedule.friday)
      end
    end
  end
end
