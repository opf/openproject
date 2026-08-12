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

RSpec.describe UserCustomFieldSections::CreateService do
  let(:admin) { build_stubbed(:admin) }
  let(:user) { build_stubbed(:user) }

  subject(:call) { described_class.new(user: current_user).call(name: "New section") }

  context "when called by an admin" do
    let(:current_user) { admin }

    it "creates the section successfully" do
      expect(call).to be_success
      expect(call.result).to be_a(UserCustomFieldSection)
      expect(call.result.name).to eq("New section")
    end

    it "persists the section to the database" do
      expect { call }.to change(UserCustomFieldSection, :count).by(1)
    end
  end

  context "when called by a non-admin" do
    let(:current_user) { user }

    it "fails authorization" do
      expect(call).not_to be_success
      expect(call.result).not_to be_persisted
    end
  end

  context "with invalid attributes" do
    let(:current_user) { admin }

    subject(:call) { described_class.new(user: admin).call(name: "") }

    it "fails validation" do
      expect(call).not_to be_success
      expect(call.result.errors[:name]).to be_present
    end
  end
end
