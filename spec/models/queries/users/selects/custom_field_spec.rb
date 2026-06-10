# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::Users::Selects::CustomField do
  before { RequestStore.clear! }

  describe ".key" do
    it "matches the cf_<id> pattern" do
      expect(described_class.key).to match("cf_42")
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

  describe ".all_available" do
    shared_let(:job_title_cf) { create(:user_custom_field, :list) }
    shared_let(:nickname_cf) { create(:user_custom_field, :string) }

    current_user { build_stubbed(:admin) }

    it "returns one select for every visible UserCustomField" do
      attributes = described_class.all_available.map(&:attribute)
      expect(attributes).to contain_exactly(:"cf_#{job_title_cf.id}", :"cf_#{nickname_cf.id}")
    end
  end

  describe "#custom_field" do
    let(:instance) { described_class.new("cf_#{custom_field_id}") }

    context "when the CF exists" do
      shared_let(:cf) { create(:user_custom_field, :string) }
      let(:custom_field_id) { cf.id }

      current_user { build_stubbed(:admin) }

      it "returns it" do
        expect(instance.custom_field).to eq(cf)
      end

      it "exposes the CF name as caption" do
        expect(instance.caption).to eq(cf.name)
      end

      it "is available" do
        expect(instance).to be_available
      end
    end

    context "when the CF does not exist" do
      let(:custom_field_id) { 999_999 }

      current_user { build_stubbed(:admin) }

      it "returns nil" do
        expect(instance.custom_field).to be_nil
      end

      it "is not available" do
        expect(instance).not_to be_available
      end
    end
  end
end
