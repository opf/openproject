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

describe TypesHelper, type: :helper do
  let(:type) { FactoryGirl.build(:type) }

  describe "#form_configuration_groups" do
    it "returns a Hash with the keys :actives and :inactives Arrays" do
      expect(form_configuration_groups(type)[:actives]).to be Array
      expect(form_configuration_groups(type)[:inactives]).to be Array
    end

    describe ":inactives" do
      subject { form_configuration_groups(type)[:inactives] }

      before do
        type.attribute_groups = [["group_one", ["attribute_one"]]]
      end

      it 'contains Hashes ordered by key :translation' do
        # The first left over attribute should currently be "date"
        expect(subject.first[:key]).to eq "date"
        expect(subject.first[:translation]).to be_present
        expect(subject.first[:translation] <= subject.second[:translation]).to be_truthy
      end

      # The "attribute_one" in "group_one" does not exist in a standard
      # OpenProject installation. It should not appear in :inactives.
      it 'does not contain attributes that do not exist anymore' do
        expect(subject.map { |inactive| inactive[:key] }).to_not include "attribute_one"
      end
    end

    describe ":actives" do
      subject { form_configuration_groups(type)[:actives] }

      before do
        allow(type).to receive(:attribute_groups).and_return [["group_one", ["date"]]]
      end

      it 'has a proper structure' do
        expect(subject.first.first).to be_a Hash
        # The group's key
        expect(subject.first.first[:key]).to eq "group_one"
        # As the key is custom, the group's translated name is the key
        expect(subject.first.first[:translation]).to eq "group_one"

        # The groups attributes
        expect(subject.first.second).to be_an Array
        expect(subject.first.second.first[:key]).to eq "date"
        expect(subject.first.second.first[:translation]).to eq "Date"
        expect(subject.first.second.first[:always_visible]).to be_falsey
      end
    end
  end
end
