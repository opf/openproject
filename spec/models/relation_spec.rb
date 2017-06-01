#-- encoding: UTF-8
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

describe Relation, type: :model do
  let(:from) { FactoryGirl.create(:work_package) }
  let(:to) { FactoryGirl.create(:work_package) }

  let(:relation) { FactoryGirl.build(:relation, from: from, to: to, relation_type: type) }

  describe 'all relation types' do
    Relation::TYPES.each do |_, type_hash|
      let(:type) { type_hash[:sym] }
      let(:reversed) { type_hash[:reverse] }

      it 'should create' do
        expect(relation.save).to eq(true)

        if reversed.nil?
          expect(relation.relation_type).to eq(type)
        else
          expect(relation.relation_type).to eq(reversed)
        end
      end
    end
  end

  describe 'follows / precedes' do
    let(:type) { Relation::TYPE_FOLLOWS }
    it 'should follows relation should be reversed' do
      expect(relation.save).to eq(true)
      relation.reload

      expect(relation.relation_type).to eq(Relation::TYPE_PRECEDES)
      expect(relation.from).to eq(to)
      expect(relation.to).to eq(from)
    end

    it 'should fail validation with invalid date and does not reverse type' do
      relation.delay = 'xx'
      expect(relation).not_to be_valid
      expect(relation.save).to eq(false)

      expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
      expect(relation.from).to eq(from)
      expect(relation.to).to eq(to)
    end
  end

  describe 'without :to and with delay set' do
    let(:relation) { FactoryGirl.build(:relation, from: from, relation_type: type, delay: 1) }
    let(:type) { Relation::TYPE_PRECEDES }

    it 'should set dates of target without to' do
      expect(relation.set_dates_of_target).to be_nil
    end
  end

  describe 'it should validate circular dependency' do
    let(:otherwp) { FactoryGirl.create(:work_package) }
    let(:relation) {
      FactoryGirl.build(:relation, from: from, to: to, relation_type: Relation::TYPE_PRECEDES)
    }
    let(:relation2) {
      FactoryGirl.build(:relation, from: to, to: otherwp, relation_type: Relation::TYPE_PRECEDES)
    }

    let(:invalid_precedes_relation) {
      FactoryGirl.build(:relation, from: otherwp, to: from, relation_type: Relation::TYPE_PRECEDES)
    }

    let(:invalid_follows_relation) {
      FactoryGirl.build(:relation, from: from, to: otherwp, relation_type: Relation::TYPE_FOLLOWS)
    }

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
