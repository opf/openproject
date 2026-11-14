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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Projects::DemoProject do
  describe ".identifier" do
    it "falls back to the classic identifier when no demo project exists" do
      expect(described_class.identifier).to eq("demo-project")
    end

    it "returns the classic identifier of a seeded demo project" do
      create(:project, identifier: "demo-project")

      expect(described_class.identifier).to eq("demo-project")
    end

    context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
      it "returns the semantic identifier of a seeded demo project" do
        create(:project, identifier: "DEMO")

        expect(described_class.identifier).to eq("DEMO")
      end

      it "returns the current identifier of a renamed demo project" do
        create(:project, identifier: "DEMO").update!(identifier: "RENAMED")

        expect(described_class.identifier).to eq("RENAMED")
      end
    end

    context "with an unrelated project identified 'demo'" do
      before { create(:project, identifier: "demo") }

      it "does not mistake it for the demo project" do
        expect(described_class.identifier).to eq("demo-project")
      end

      it "prefers the seeded demo project" do
        create(:project, identifier: "demo-project")

        expect(described_class.identifier).to eq("demo-project")
      end
    end
  end

  describe ".identifier?" do
    it "recognizes both seeded identifiers" do
      expect(described_class).to be_identifier("demo-project")
      expect(described_class).to be_identifier("DEMO")
    end

    it "does not recognize other identifiers" do
      expect(described_class).not_to be_identifier("demo")
      expect(described_class).not_to be_identifier("other")
    end
  end
end
