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

require "rails_helper"

RSpec.describe WorkPackages::Admin::Settings::IdentifierAutofixSectionComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  def build_entry(name:, identifier:, handle:, error_reason:)
    project = instance_double(Project, name:, id: rand(1..9999), to_param: identifier)
    {
      project:,
      current_identifier: identifier,
      suggested_identifier: handle,
      error_reason:
    }
  end

  let(:entry_special_chars) do
    build_entry(name: "Flight Planning", identifier: "flight-planning", handle: "FP", error_reason: :special_characters)
  end
  let(:entry_too_long) do
    build_entry(name: "Very Long Name Project", identifier: "verylongnameproject", handle: "VLNP", error_reason: :too_long)
  end

  subject(:component) { described_class.new(projects_data: projects_data) }

  context "with fewer than 5 projects" do
    let(:projects_data) { [entry_special_chars, entry_too_long] }

    it "renders all entries without a footer" do
      render_inline(component)
      expect(page).to have_text("Flight Planning")
      expect(page).to have_text("Very Long Name Project")
      expect(page).to have_no_text("more project")
    end

    it "shows the previous identifier" do
      render_inline(component)
      expect(page).to have_text("flight-planning")
      expect(page).to have_text("verylongnameproject")
    end

    it "shows the suggested handle" do
      render_inline(component)
      expect(page).to have_text("FP")
      expect(page).to have_text("VLNP")
    end

    it "shows a realistic example work package ID" do
      render_inline(component)
      # Numbers are deterministic from the identifier's byte sum.
      expect(page).to have_text("FP-151")    # "FP".bytes.sum % 500 + 1 = 151
      expect(page).to have_text("VLNP-321")  # "VLNP".bytes.sum % 500 + 1 = 321
    end

    it "shows the special characters error caption" do
      render_inline(component)
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.autofix_preview.error_special_characters"))
    end

    it "shows the too long error caption" do
      render_inline(component)
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.autofix_preview.error_too_long"))
    end

    it "renders the warning banner with the total project count" do
      render_inline(component)
      expect(page).to have_text(
        I18n.t(
          "admin.settings.work_packages_identifier.banner.existing_identifiers_notice",
          project_count: 2
        )
      )
    end
  end

  context "with exactly 5 projects" do
    let(:projects_data) do
      Array.new(5) do |i|
        build_entry(name: "Project #{i}", identifier: "proj-#{i}", handle: "P#{i}", error_reason: :special_characters)
      end
    end

    it "renders all 5 entries without a footer" do
      render_inline(component)
      expect(page).to have_no_text("more project")
    end
  end

  context "with more than 5 projects" do
    let(:projects_data) do
      Array.new(8) do |i|
        build_entry(name: "Project #{i}", identifier: "proj-#{i}", handle: "P#{i}X", error_reason: :special_characters)
      end
    end

    it "renders only the first 5 entries" do
      render_inline(component)
      expect(page).to have_text("Project 0")
      expect(page).to have_text("Project 4")
      expect(page).to have_no_text("Project 5")
    end

    it "shows a footer with the remaining count" do
      render_inline(component)
      expect(page).to have_text("3 more projects")
    end
  end

  context "with exactly 6 projects" do
    let(:projects_data) do
      Array.new(6) do |i|
        build_entry(name: "Project #{i}", identifier: "proj-#{i}", handle: "P#{i}X", error_reason: :special_characters)
      end
    end

    it "shows '1 more project' (singular)" do
      render_inline(component)
      expect(page).to have_text("1 more project")
    end
  end

  context "with column headers" do
    let(:projects_data) { [entry_special_chars] }

    it "renders all four column headers" do
      render_inline(component)
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.box_header.label_project"))
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.box_header.label_previous_identifier"))
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.box_header.label_autofixed_suggestion"))
      expect(page).to have_text(I18n.t("admin.settings.work_packages_identifier.box_header.label_example_work_package_id"))
    end
  end
end
