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

RSpec.describe Queries::Projects::Orders::CustomFieldOrder do
  describe ".key" do
    before do
      where = double
      where_not = double
      visible = double

      allow(ProjectCustomField).to receive(:where).and_return(where)
      allow(where).to receive(:not).with(field_format: %w[text]).and_return(where_not)
      allow(where_not).to receive(:visible).and_return(visible)
      allow(visible).to receive(:pluck).with(:id).and_return([42])
    end

    it "matches key in correct format for existing custom field" do
      expect(described_class.key).to match("cf_42")
    end

    it "doesn't match key in correct format for not found custom field" do
      expect(described_class.key).not_to match("cf_43")
    end

    it "doesn't match non numerical id" do
      expect(described_class.key).not_to match("cf_cf")
    end

    it "doesn't match with prefix" do
      expect(described_class.key).not_to match("xcf_42")
    end

    it "doesn't match with suffix" do
      expect(described_class.key).not_to match("cf_42x")
    end
  end

  describe "#available?" do
    let(:instance) { described_class.new("cf_#{custom_field.id}") }

    before do
      allow(User).to receive(:current).and_return build_stubbed(:admin)
    end

    context "for int custom field" do
      let!(:custom_field) { create(:project_custom_field, :integer) }

      it "allows to sort by it" do
        expect(instance).to be_available
      end
    end

    context "for text custom field" do
      let!(:custom_field) { create(:project_custom_field, :text) }

      it "does not allow to sort by it" do
        expect(instance).not_to be_available
      end
    end
  end
end
