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

RSpec.describe "Project settings work package custom fields", :js do
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:converted) do
    create(:type_variant, type: epic, variant_name: "Epic without Severity", created_by_migration: true)
  end
  shared_let(:story_points) { create(:integer_wp_custom_field, name: "Story points", types: [converted]) }
  shared_let(:unused_field) { create(:integer_wp_custom_field, name: "Nowhere in sight") }

  let(:project) { create(:project, types: [converted]) }

  current_user do
    create(:user, member_with_permissions: { project => %i[edit_project manage_types manage_project_variants] })
  end

  before { visit project_settings_work_packages_custom_fields_path(project) }

  it "lists the fields the applied variants show, and names the variant showing each" do
    within_test_selector("project-custom-field-#{story_points.id}") do
      expect(page).to have_text("Story points")
      expect(page).to have_text(converted.composite_name)
    end

    expect(page).to have_no_text(unused_field.name)
  end

  it "explains the variants a migration created on the banner" do
    expect(page).to have_test_selector("migrated-variants-banner",
                                       text: I18n.t("types.index.migrated_variants_banner.cleanup").strip)
  end

  it "is reachable from the work package settings tabs" do
    visit project_settings_work_packages_types_path(project)

    click_on I18n.t(:label_custom_field_plural)

    expect(page).to have_current_path(project_settings_work_packages_custom_fields_path(project))
  end

  context "without permission to configure types" do
    current_user do
      create(:user, member_with_permissions: { project => %i[edit_project] })
    end

    it "is refused" do
      expect(page).to have_text(I18n.t(:notice_not_authorized))
    end
  end
end
