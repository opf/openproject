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

RSpec.describe Queries::Users::CustomFieldContext do
  describe ".custom_field_class" do
    it "is UserCustomField" do
      expect(described_class.custom_field_class).to eq(UserCustomField)
    end
  end

  describe ".model" do
    it "is User" do
      expect(described_class.model).to eq(User)
    end
  end

  describe ".customized_type" do
    it "is 'Principal' since all users share the Principal STI base in custom_values" do
      expect(described_class.customized_type).to eq("Principal")
    end
  end

  describe ".custom_fields" do
    shared_let(:visible_cf) { create(:user_custom_field, :string) }
    shared_let(:admin_only_cf) { create(:user_custom_field, :string, admin_only: true) }

    context "as a non-admin user" do
      shared_let(:user) { create(:user) }

      before { login_as(user) }

      it "returns only non-admin-only user custom fields" do
        expect(described_class.custom_fields).to contain_exactly(visible_cf)
      end
    end

    context "as an admin user" do
      shared_let(:admin) { create(:admin) }

      before { login_as(admin) }

      it "returns all user custom fields" do
        expect(described_class.custom_fields).to contain_exactly(visible_cf, admin_only_cf)
      end
    end
  end

  describe ".where_subselect_joins" do
    let(:custom_field) { build_stubbed(:user_custom_field, :list, id: 42) }

    it "produces a LEFT OUTER JOIN onto custom_values via the Principal STI base" do
      sql = described_class.where_subselect_joins(custom_field)

      expect(sql).to include("LEFT OUTER JOIN custom_values")
      # User/Group/PlaceholderUser all persist as Principal in custom_values.customized_type;
      # the per-CF join keeps user CFs distinct.
      expect(sql).to include("custom_values.customized_type = 'Principal'")
      expect(sql).to include("custom_values.customized_id = users.id")
      expect(sql).to include("custom_values.custom_field_id = #{custom_field.id}")
    end
  end

  describe ".where_subselect_conditions" do
    it "is nil since users have no per-record visibility scoping for CF reads" do
      expect(described_class.where_subselect_conditions).to be_nil
    end
  end

  describe ".find_custom_field" do
    shared_let(:admin) { create(:admin) }
    shared_let(:cf) { create(:user_custom_field, :string) }

    before do
      RequestStore.clear!
      login_as(admin)
    end

    it "returns the custom field for an existing id" do
      expect(described_class.find_custom_field(cf.id)).to eq(cf)
    end

    it "returns nil for a missing id" do
      expect(described_class.find_custom_field(0)).to be_nil
    end

    it "memoizes lookups in RequestStore" do
      described_class.find_custom_field(cf.id)

      expect { described_class.find_custom_field(cf.id) }.to have_a_query_limit(0)
    end

    it "memoizes nil for missing ids" do
      described_class.find_custom_field(0)

      expect { described_class.find_custom_field(0) }.to have_a_query_limit(0)
    end
  end
end
