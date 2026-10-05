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
require_relative "../../support/query_counter"

RSpec.describe ::Screens::Resolver do
  let(:project) { create(:project) }
  let(:type) { create(:type) }

  before do
    ProjectType.create!(project:, type:)
    ::Screens::Resolver.reset_cache
  end

  after do
    described_class.raise_on_error = false
    ::Screens::Resolver.reset_cache
  end

  def build_screen(screen, items)
    section = create(:screen_section, screen:, name: "General", position: 1)
    items.each_with_index do |(key, attrs), index|
      create(:screen_item, screen:, section:, field_key: key, position: index + 1, **attrs)
    end
    screen
  end

  def assign(screen, context: :create)
    scheme = create(:screen_scheme)
    create(:screen_scheme_item, scheme:, type:, **{ "#{context}_screen": screen })
    create(:project_screen_scheme, project:, scheme:)
    scheme
  end

  describe ".for" do
    it "raises for an invalid context" do
      expect { described_class.for(project, type, :foo) }.to raise_error(ArgumentError)
    end

    it "returns native with no_scheme" do
      result = described_class.for(project, type, :create)
      expect(result).to be_native
      expect(result.reason).to eq("no_scheme")
    end

    it "returns type_not_in_project when the type is not enabled" do
      ProjectType.where(project_id: project.id, type_id: type.id).delete_all
      result = described_class.for(project.reload, type, :create)
      expect(result.reason).to eq("type_not_in_project")
    end

    it "returns the screen layout with ordered fields" do
      screen = build_screen(create(:create_screen), [["subject", {}], ["priority", { width: "half" }]])
      assign(screen)

      result = described_class.for(project, type, :create)
      expect(result).to be_screen
      expect(result.field_keys).to eq(%w[subject priority])
      expect(result.sections.first[:fields].last[:width]).to eq("half")
    end

    it "falls back from view to edit" do
      screen = create(:edit_screen)
      assign(screen, context: :edit)

      expect(described_class.for(project, type, :view).screen).to eq(screen)
    end

    it "excludes invisible fields from fields but reports them in diagnostics" do
      screen = build_screen(create(:create_screen), [["subject", {}], ["priority", { visible: false }]])
      assign(screen)

      result = described_class.for(project, type, :create)
      expect(result.field_keys).to eq(%w[subject])
      expect(result.diagnostics[:not_visible]).to include("priority")
    end

    it "uses the edit screen for a view slot that is not set" do
      scheme = create(:screen_scheme)
      create(:screen_scheme_item, scheme:, type:, edit_screen: create(:edit_screen))
      create(:project_screen_scheme, project:, scheme:)

      result = described_class.for(project, type, :view)
      expect(result).to be_screen
      expect(result.screen.screen_type).to eq("edit")
    end

    it "caches results within a request" do
      screen = build_screen(create(:create_screen), [["subject", {}]])
      assign(screen)

      described_class.for(project, type, :create)
      count = ScreensQueryCounter.count { described_class.for(project, type, :create) }
      expect(count).to eq(0)
    end

    it "fails open on internal errors" do
      allow(described_class).to receive(:project_assignment).and_raise("boom")
      allow(Rails.error).to receive(:report)

      result = described_class.for(project, type, :create)
      expect(result).to be_native
      expect(result.reason).to eq("error")
      expect(result.diagnostics[:error]).to be(true)
    end

    it "re-raises when raise_on_error is set" do
      described_class.raise_on_error = true
      allow(described_class).to receive(:project_assignment).and_raise("boom")
      expect { described_class.for(project, type, :create) }.to raise_error("boom")
    end
  end

  describe ".matrix" do
    it "matches for for the same type and context" do
      screen = build_screen(create(:create_screen), [["subject", {}]])
      assign(screen)

      matrix = described_class.matrix(project)
      expect(matrix.dig(type.id, :create)[:source]).to eq("screen")
      expect(described_class.for(project, type, :create).source).to eq(:screen)
    end
  end
end
