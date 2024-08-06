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

RSpec.describe TypesHelper do
  let(:type) { build_stubbed(:type) }

  describe "#form_configuration_groups" do
    it "returns a Hash with the keys :actives and :inactives Arrays" do
      expect(helper.form_configuration_groups(type)[:actives]).to be_an Array
      expect(helper.form_configuration_groups(type)[:inactives]).to be_an Array
    end

    describe ":inactives" do
      subject { helper.form_configuration_groups(type)[:inactives] }

      before do
        allow(type)
          .to receive(:attribute_groups)
          .and_return [Type::AttributeGroup.new(type, "group one", ["assignee"])]
      end

      it "contains Hashes ordered by key :translation" do
        # The first left over attribute should currently be "date"
        expect(subject.first[:translation]).to be_present
        expect(subject.first[:translation] <= subject.second[:translation]).to be_truthy
      end

      # The "assignee" is in "group one". It should not appear in :inactives.
      it "does not contain attributes that do not exist anymore" do
        expect(subject.pluck(:key)).not_to include "assignee"
      end
    end

    describe ":actives" do
      subject { helper.form_configuration_groups(type)[:actives] }

      before do
        allow(type)
          .to receive(:attribute_groups)
          .and_return [Type::AttributeGroup.new(type, "group one", ["date"])]
      end

      it "has a proper structure" do
        # The group's name/key
        expect(subject.first[:name]).to eq "group one"

        # The groups attributes
        expect(subject.first[:attributes]).to be_an Array
        expect(subject.first[:attributes].first[:key]).to eq "date"
        expect(subject.first[:attributes].first[:translation]).to eq "Date"
      end
    end
  end
end
