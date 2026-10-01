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

RSpec.describe Queries::Projects::CustomFieldContext do
  shared_let(:admin) { create(:admin) }
  shared_let(:custom_field1) { create(:project_custom_field) }
  shared_let(:custom_field2) { create(:project_custom_field) }

  before do
    RequestStore.clear!
    login_as(admin)
  end

  describe ".find_custom_field" do
    it "returns the custom field for a valid id" do
      expect(described_class.find_custom_field(custom_field1.id)).to eq(custom_field1)
    end

    it "returns nil for a non-existent id" do
      expect(described_class.find_custom_field(0)).to be_nil
    end

    it "caches the result in RequestStore" do
      described_class.find_custom_field(custom_field1.id)

      expect { described_class.find_custom_field(custom_field1.id) }.to have_a_query_limit(0)
    end

    it "caches nil for non-existent ids" do
      described_class.find_custom_field(0)

      expect { described_class.find_custom_field(0) }.to have_a_query_limit(0)
    end
  end
end
