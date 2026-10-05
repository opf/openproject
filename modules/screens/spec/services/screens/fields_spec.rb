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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Screens::Fields do
  after { described_class.reset_registry! }

  describe ".placeable?" do
    it "accepts the native extras" do
      expect(described_class).to be_placeable("subject")
      expect(described_class).to be_placeable("description")
      expect(described_class).to be_placeable("status")
    end

    it "rejects excluded keys" do
      %w[id author type project created_at updated_at].each do |key|
        expect(described_class).not_to be_placeable(key)
      end
    end

    it "rejects malformed keys" do
      expect(described_class).not_to be_placeable("; drop")
      expect(described_class).not_to be_placeable("1abc")
      expect(described_class).not_to be_placeable("a" * 65)
    end

    it "rejects a custom field that does not exist" do
      expect(described_class).not_to be_placeable("custom_field_999999")
    end

    it "rejects watchers until a module registers it" do
      expect(described_class).not_to be_placeable("watchers")
      described_class.register("watchers", label: "Watchers")
      expect(described_class).to be_placeable("watchers")
    end
  end

  describe ".available?" do
    let(:project) { create(:project) }
    let(:type) { create(:type) }

    it "fails open when the variant is missing" do
      expect(described_class.available?("subject", project: nil, type:)).to be(true)
      expect(described_class.available?("subject", project:, type: nil)).to be(true)
    end

    it "rejects a custom field that is not active in the project" do
      custom_field = create(:work_package_custom_field)
      expect(described_class.available?("custom_field_#{custom_field.id}", project:, type:)).to be(false)
    end
  end

  describe ".label" do
    it "falls back to the work package attribute name" do
      expect(described_class.label("subject")).to be_present
    end
  end
end
