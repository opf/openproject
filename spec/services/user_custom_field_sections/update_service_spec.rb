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

require "spec_helper"

RSpec.describe UserCustomFieldSections::UpdateService do
  let(:admin) { build_stubbed(:admin) }
  let(:user) { build_stubbed(:user) }
  let(:section) { create(:user_custom_field_section, name: "Original name") }

  context "when called by an admin" do
    subject(:call) { described_class.new(user: admin, model: section).call(name: "Updated name") }

    it "updates the section successfully" do
      expect(call).to be_success
      expect(section.reload.name).to eq("Updated name")
    end
  end

  context "when called by a non-admin" do
    subject(:call) { described_class.new(user: user, model: section).call(name: "Updated name") }

    it "fails authorization" do
      expect(call).not_to be_success
      expect(section.reload.name).to eq("Original name")
    end
  end

  context "with invalid attributes" do
    subject(:call) { described_class.new(user: admin, model: section).call(name: "") }

    it "fails validation" do
      expect(call).not_to be_success
      expect(call.result.errors[:name]).to be_present
    end
  end

  context "when moving position" do
    let!(:section_a) { create(:user_custom_field_section, position: 1) }
    let!(:section_b) { create(:user_custom_field_section, position: 2) }

    it "reorders sections when moving up" do
      described_class.new(user: admin, model: section_b).call(move_to: :highest)
      expect(section_b.reload.position).to eq(1)
    end
  end
end
