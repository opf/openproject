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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFields::Hierarchy::GenerateRootContract, with_ee: [:custom_field_hierarchies] do
  subject { described_class.new }

  describe "#call" do
    context "when hierarchy_root is nil" do
      let(:custom_field) { create(:hierarchy_wp_custom_field, hierarchy_root: nil) }

      it "is valid" do
        result = subject.call(custom_field:)
        expect(result).to be_success
      end
    end

    context "when hierarchy_root is not nil" do
      let(:hierarchy_root) { create(:hierarchy_item) }
      let(:custom_field) { create(:hierarchy_wp_custom_field, hierarchy_root:) }

      it "is invalid" do
        result = subject.call(custom_field:)
        expect(result).to be_failure
        expect(result.errors[:custom_field]).to match_array("must not be defined.")
      end
    end

    context "when custom field format is not supported" do
      let(:custom_field) { create(:string_wp_custom_field) }

      it "is invalid" do
        result = subject.call(custom_field:)
        expect(result).to be_failure
        expect(result.errors[:custom_field]).to match_array("format 'string' is unsupported.")
      end
    end

    context "when inputs are valid", with_ee: %i[weighted_item_lists] do
      let(:custom_field) { create(:weighted_item_list_wp_custom_field, hierarchy_root: nil) }

      it "creates a success result" do
        expect(subject.call(custom_field:)).to be_success
      end
    end

    it "accepts a list custom field" do
      custom_field = create(:list_wp_custom_field)

      expect(described_class.new.call(custom_field:)).to be_success
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          {},
          { hierarchy_root: create(:hierarchy_item) },
          { hierarchy_root: "" },
          { hierarchy_root: 42 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
end
