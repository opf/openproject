# frozen_string_literal: true

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

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::UpdateItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let(:vader) { create(:hierarchy_item) }
    let(:luke) { create(:hierarchy_item, label: "luke", short: "ls", parent: vader) }
    let(:leia) { create(:hierarchy_item, label: "leia", short: "lo", parent: vader) }

    before do
      luke
      leia
    end

    context "when all required fields are valid" do
      it "is valid" do
        [
          { item: luke, label: "Luke Skywalker", short: "LS" },
          { item: luke, label: "Luke Skywalker" },
          { item: luke, short: "LS" },
          { item: luke, short: "lo" },
          { item: luke }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when item is a root item" do
      let(:params) { { item: vader } }

      it("is invalid") do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(item: ["must not be a root item"])
      end
    end

    context "when item is not of type 'Item'" do
      let(:invalid_item) { create(:custom_field) }
      let(:params) { { item: invalid_item } }

      it("is invalid") do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(item: ["must be CustomField::Hierarchy::Item"])
      end
    end

    context "when item is not persisted" do
      let(:item) { build(:hierarchy_item, parent: vader) }
      let(:params) { { item: } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(item: ["must exist"])
      end
    end

    context "when the label already exist in the same hierarchy level" do
      let(:params) { { item: luke, label: "leia" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["must be unique at the same hierarchical level"])
      end
    end

    context "when fields are invalid" do
      it "is invalid" do
        [
          {},
          { item: nil },
          { item: luke, label: nil },
          { item: luke, label: 42 },
          { item: luke, short: nil },
          { item: luke, short: 42 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
