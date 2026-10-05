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

RSpec.describe ::Screens::ScreenService do
  describe ".create" do
    it "creates the screen with its layout" do
      result = described_class.create(name: "Create screen", screen_type: "create",
                                      sections: [{ name: "General", items: [{ field_key: "subject" }] }])
      expect(result).to be_success
      expect(result.result.sections.first.items.pluck(:field_key)).to eq(%w[subject])
    end
  end

  describe ".update" do
    it "does not change the screen_type" do
      screen = create(:screen, screen_type: "create")
      described_class.update(screen, screen_type: "edit")
      expect(screen.reload.screen_type).to eq("create")
    end
  end

  describe ".clone" do
    it "creates an inactive copy with a new name and the same layout" do
      screen = create(:create_screen)
      section = create(:screen_section, screen:)
      create(:screen_item, screen:, section:, field_key: "subject")

      result = described_class.clone(screen)
      copy = result.result
      expect(copy.name).to include("Copy of")
      expect(copy.active).to be(false)
      expect(copy.screen_type).to eq("create")
      expect(copy.sections.first.items.pluck(:field_key)).to eq(%w[subject])
    end
  end

  describe ".impact" do
    it "counts schemes and projects using the screen" do
      screen = create(:create_screen)
      scheme = create(:screen_scheme)
      create(:screen_scheme_item, scheme:, type: create(:type), create_screen: screen)
      create(:project_screen_scheme, scheme:)

      expect(described_class.impact(screen)[:scheme_count]).to eq(1)
      expect(described_class.impact(screen)[:project_count]).to eq(1)
    end
  end

  describe ".deactivate and .activate" do
    it "toggles active" do
      screen = create(:screen)
      described_class.deactivate(screen)
      expect(screen.reload.active).to be(false)
      described_class.activate(screen)
      expect(screen.reload.active).to be(true)
    end
  end
end
