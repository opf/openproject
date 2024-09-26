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

RSpec.describe Queries::Projects::Selects::CustomField do
  describe ".key" do
    it "matches key in correct format" do
      expect(described_class.key).to match("cf_42")
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

  describe "#custom_field" do
    let(:instance) { described_class.new(name) }
    let(:name) { "cf_42" }
    let(:id) { 42 }

    before do
      visible = double

      allow(ProjectCustomField).to receive(:visible).and_return(visible)
      allow(visible).to receive(:find_by).with(id: id.to_s).and_return(custom_field)
    end

    context "when custom field exists" do
      let(:custom_field) { instance_double(ProjectCustomField) }

      it "returns the custom field" do
        expect(instance.custom_field).to eq(custom_field)
      end

      it "memoizes the custom field" do
        2.times { instance.custom_field }

        expect(ProjectCustomField).to have_received(:visible).once
      end
    end

    context "when custom field doesn't exist" do
      let(:custom_field) { nil }

      it "returns the custom field" do
        expect(instance.custom_field).to be_nil
      end

      it "memoizes the custom field" do
        2.times { instance.custom_field }

        expect(ProjectCustomField).to have_received(:visible).once
      end
    end
  end
end
