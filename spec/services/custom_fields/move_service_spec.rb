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

RSpec.describe CustomFields::MoveService do
  let(:admin) { build(:admin) }

  shared_examples "moves fields within a section" do |cf_factory:, section_factory:, section_assoc:|
    let(:section) { create(section_factory) }
    let!(:cf1) { create(cf_factory, section_assoc => section) }
    let!(:cf2) { create(cf_factory, section_assoc => section) }
    let!(:cf3) { create(cf_factory, section_assoc => section) }

    subject(:service) { described_class.new(user: admin, custom_field: cf2) }

    it "moves higher" do
      result = service.call(move_to: "higher")
      expect(result).to be_success
      order = section.reload.attribute_order
      expect(order.index(cf2.column_name)).to be < order.index(cf1.column_name)
    end

    it "moves lower" do
      result = service.call(move_to: "lower")
      expect(result).to be_success
      order = section.reload.attribute_order
      expect(order.index(cf2.column_name)).to be > order.index(cf1.column_name)
    end

    it "moves to the top" do
      service.call(move_to: "highest")
      expect(section.reload.attribute_order.first).to eq(cf2.column_name)
    end

    it "moves to the bottom" do
      service.call(move_to: "lowest")
      expect(section.reload.attribute_order.last).to eq(cf2.column_name)
    end

    context "when user is not admin" do
      let(:admin) { build(:user) }

      it "returns a failure" do
        expect(service.call(move_to: "higher")).not_to be_success
      end
    end
  end

  describe "with UserCustomField" do
    include_examples "moves fields within a section",
                     cf_factory: :user_custom_field,
                     section_factory: :user_custom_field_section,
                     section_assoc: :user_custom_field_section
  end

  describe "with ProjectCustomField" do
    include_examples "moves fields within a section",
                     cf_factory: :project_custom_field,
                     section_factory: :project_custom_field_section,
                     section_assoc: :project_custom_field_section
  end
end
