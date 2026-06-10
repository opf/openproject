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

RSpec.describe Queries::Users::Orders::CustomFieldOrder do
  before { RequestStore.clear! }

  describe ".key" do
    before do
      where = double
      where_not = double
      visible = double

      allow(UserCustomField).to receive(:where).and_return(where)
      allow(where).to receive(:not).with(field_format: %w[text]).and_return(where_not)
      allow(where_not).to receive(:visible).and_return(visible)
      allow(visible).to receive(:pluck).with(:id).and_return([42])
    end

    it "matches an existing sortable user CF id" do
      expect(described_class.key).to match("cf_42")
    end

    it "does not match an unknown id" do
      expect(described_class.key).not_to match("cf_43")
    end

    it "does not match a non-numeric id" do
      expect(described_class.key).not_to match("cf_cf")
    end

    it "does not match with a prefix" do
      expect(described_class.key).not_to match("xcf_42")
    end

    it "does not match with a suffix" do
      expect(described_class.key).not_to match("cf_42x")
    end
  end

  describe "#available?" do
    let(:instance) { described_class.new("cf_#{custom_field.id}") }

    current_user { build_stubbed(:admin) }

    context "for an integer CF" do
      let!(:custom_field) { create(:user_custom_field, :integer) }

      it "is sortable" do
        expect(instance).to be_available
      end
    end

    context "for a list CF" do
      let!(:custom_field) { create(:user_custom_field, :list) }

      it "is sortable" do
        expect(instance).to be_available
      end
    end

    context "for a text CF" do
      let!(:custom_field) { create(:user_custom_field, :text) }

      it "is excluded from sortable orders" do
        expect(instance).not_to be_available
      end
    end
  end

  describe "#custom_field" do
    let(:instance) { described_class.new("cf_42") }

    before do
      where = double
      where_not = double
      visible = double

      allow(UserCustomField).to receive(:where).and_return(where)
      allow(where).to receive(:not).with(field_format: %w[text]).and_return(where_not)
      allow(where_not).to receive(:visible).and_return(visible)
      allow(visible).to receive(:find_by).with(id: "42").and_return(custom_field)
    end

    context "when the CF exists and is sortable" do
      let(:custom_field) { instance_double(UserCustomField) }

      it "returns it" do
        expect(instance.custom_field).to eq(custom_field)
      end

      it "memoizes the lookup" do
        2.times { instance.custom_field }

        expect(UserCustomField).to have_received(:where).once
      end
    end

    context "when the CF does not exist" do
      let(:custom_field) { nil }

      it "returns nil" do
        expect(instance.custom_field).to be_nil
      end

      it "still memoizes the lookup" do
        2.times { instance.custom_field }

        expect(UserCustomField).to have_received(:where).once
      end
    end
  end
end
