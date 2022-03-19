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
require 'spec_helper'

describe Relation, type: :model do
  let(:from) { create(:work_package) }
  let(:to) { create(:work_package) }
  let(:type) { 'relates' }
  let(:relation) { build(:relation, from: from, to: to, relation_type: type) }

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
        expect(relation.save).to eq(true)
        relation.reload

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end

      it 'fails validation with invalid date and reverses' do
        relation.delay = 'xx'
        expect(relation).not_to be_valid
        expect(relation.save).to eq(false)

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end
    end

    context 'for PRECEDES' do
      let(:type) { Relation::TYPE_PRECEDES }

      it 'is reversed' do
        expect(relation.save).to eq(true)
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
end
