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

RSpec.describe Labels::FindOrCreateService do
  shared_let(:user) { create(:admin) }

  subject(:call) { described_class.new(user:).call(name:) }

  context "when no label with that name exists" do
    let(:name) { "Bug" }

    it "creates the label" do
      expect(call).to be_success
      expect(call.result).to be_persisted
      expect(call.result.name).to eq("Bug")
      expect(call.result).to be_previously_new_record
    end
  end

  context "when a label with the same name in different casing exists" do
    shared_let(:existing) { create(:label, name: "bug") }

    let(:name) { "  BUG " }

    it "returns the existing label without creating another one" do
      expect { call }.not_to change(Label, :count)

      expect(call).to be_success
      expect(call.result).to eq(existing)
      expect(call.result).not_to be_previously_new_record
    end

    context "with a name Ruby and Postgres lowercase differently" do
      shared_let(:existing) { create(:label, name: "İstanbul") }

      let(:name) { "İstanbul" }

      it "still returns the existing label" do
        expect(call).to be_success
        expect(call.result).to eq(existing)
      end
    end
  end

  context "when another request creates the label between lookup and validation" do
    let(:name) { "Bug" }

    before do
      allow(Labels::CreateService).to receive(:new).and_wrap_original do |original, **args|
        create(:label, name: "bug")
        original.call(**args)
      end
    end

    it "returns the label created by the other request" do
      expect(call).to be_success
      expect(call.result.name).to eq("bug")
      expect(Label.count).to eq(1)
    end
  end

  context "when another request creates the label between validation and insert" do
    let(:name) { "Bug" }

    before do
      create(:label, name: "bug")

      lookups = 0
      allow(Label).to receive(:named).and_wrap_original do |original, *args|
        lookups += 1
        lookups == 1 ? Label.none : original.call(*args)
      end
      allow_any_instance_of(Label).to receive(:valid?).and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it "returns the label created by the other request" do
      expect(call).to be_success
      expect(call.result.name).to eq("bug")
      expect(Label.count).to eq(1)
    end
  end

  context "when the user lacks the permission to edit work packages" do
    shared_let(:user) { create(:user) }

    let(:name) { "Bug" }

    it "fails" do
      expect(call).to be_failure
      expect(call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "with a blank name" do
    let(:name) { " " }

    it "fails" do
      expect(call).to be_failure
      expect(call.errors.symbols_for(:name)).to include(:blank)
    end
  end
end
