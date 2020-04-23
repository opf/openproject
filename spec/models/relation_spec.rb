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

describe Relation, type: :model do
  let(:from) { FactoryBot.create(:work_package) }
  let(:to) { FactoryBot.create(:work_package) }
  let(:type) { 'relates' }
  let(:relation) { FactoryBot.build(:relation, from: from, to: to, relation_type: type) }

  describe 'all relation types' do
    Relation::TYPES.each do |key, type_hash|
      let(:type) { key }
      let(:column_name) { type_hash[:sym] }
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

      it "sets the correct column for '#{key}' to 1" do
        expect(relation.send(column_name))
          .to eql 1
      end
    end
  end

  describe '#relation_type' do
    Relation::TYPES.each do |key, type_hash|
      let(:column_name) { type_hash[:sym] }
      let(:type) { key }
      let(:reversed) { type_hash[:reverse] }
      let(:relation) do
        FactoryBot.build_stubbed(:relation,
                                 relation_type: nil,
                                 column_name => column_count)
      end

      context 'with the column set to 1' do
        let(:column_count) { 1 }

        it 'deduces the name from the column' do
          if reversed.nil?
            expect(relation.relation_type).to eq(type)
          else
            expect(relation.relation_type).to eq(reversed)
          end
        end
      end

      context 'with the column set to 2' do
        let(:column_count) { 2 }

        it 'deduces the name from the column' do
          if reversed.nil?
            expect(relation.relation_type).to eq(type)
          else
            expect(relation.relation_type).to eq(reversed)
          end
        end
      end

      context 'with the column set to 1 and another column also set to 1' do
        let(:column_count) { 1 }
        let(:other_column) do
          if type == Relation::TYPE_RELATES
            Relation::TYPE_DUPLICATES
          else
            Relation::TYPE_RELATES
          end
        end
        let(:relation) do
          FactoryBot.build_stubbed(:relation,
                                   relation_type: nil,
                                   column_name => 1,
                                   other_column => 1)
        end

        it 'is "mixed"' do
          expect(relation.relation_type)
            .to eql 'mixed'
        end
      end
    end
  end

  describe '#relation_type=' do
    let(:type) { Relation::TYPE_RELATES }

    it 'updates the column value' do
      relation.save!
      expect(relation.relates).to eq 1

      relation.relation_type = 'duplicates'
      relation.save!
      expect(relation.relation_type).to eq('duplicates')

      expect(relation.relates).to eq 0
      expect(relation.duplicates).to eq 1
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

  describe '.visible' do
    let(:user) { FactoryBot.create(:user) }
    let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
    let(:member_project_to) do
      FactoryBot.create(:member,
                        project: to.project,
                        user: user,
                        roles: [role])
    end

    let(:member_project_from) do
      FactoryBot.create(:member,
                        project: from.project,
                        user: user,
                        roles: [role])
    end

    before do
      relation.save!
    end

    context 'user can see both work packages' do
      before do
        member_project_to
        member_project_from
      end

      it 'returns the relation' do
        expect(Relation.visible(user))
          .to match_array([relation])
      end
    end

    context 'user can see only the from work packages' do
      before do
        member_project_from
      end

      it 'does not return the relation' do
        expect(Relation.visible(user))
          .to be_empty
      end
    end

    context 'user can see only the to work packages' do
      before do
        member_project_to
      end

      it 'does not return the relation' do
        expect(Relation.visible(user))
          .to be_empty
      end
    end
  end

  describe 'it should validate circular dependency' do
    let(:otherwp) { FactoryBot.create(:work_package) }
    let(:relation) do
      FactoryBot.build(:relation, from: from, to: to, relation_type: Relation::TYPE_PRECEDES)
    end
    let(:relation2) do
      FactoryBot.build(:relation, from: to, to: otherwp, relation_type: Relation::TYPE_PRECEDES)
    end

    let(:invalid_precedes_relation) do
      FactoryBot.build(:relation, from: otherwp, to: from, relation_type: Relation::TYPE_PRECEDES)
    end

    let(:invalid_follows_relation) do
      FactoryBot.build(:relation, from: from, to: otherwp, relation_type: Relation::TYPE_FOLLOWS)
    end

    it 'prevents invalid precedes relations' do
      expect(relation.save).to eq(true)
      expect(relation2.save).to eq(true)
      from.reload
      to.reload
      otherwp.reload
      expect(invalid_precedes_relation.save).to eq(false)
      expect(invalid_precedes_relation.errors[:base]).not_to be_empty
    end

    it 'prevents invalid follows relations' do
      expect(relation.save).to eq(true)
      expect(relation2.save).to eq(true)
      from.reload
      to.reload
      otherwp.reload
      expect(invalid_follows_relation.save).to eq(false)
      expect(invalid_follows_relation.errors[:base]).not_to be_empty
    end
  end
end
