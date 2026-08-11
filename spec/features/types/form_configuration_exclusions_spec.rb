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

RSpec.describe "form configuration exclusions", :js,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

  let(:owner) do
    create(:type).tap do |type|
      type.attribute_groups = [["People", %w[assignee responsible]]]
      type.save!
    end
  end

  let(:variant) { create(:type, parent: owner) }
  let(:link) { variant.configuration_links.find_by(aspect:) }

  def toggle_for(key)
    page.find("[data-test-selector='toggle-form-config-exclusion-#{key}'] > button")
  end

  def expect_toggle(key, pressed:)
    expect(page)
      .to have_css("[data-test-selector='toggle-form-config-exclusion-#{key}'] > button[aria-pressed='#{pressed}']")
  end

  before do
    variant.link!(aspect, source: owner)
    login_as admin
    visit edit_type_form_configuration_path(variant)
  end

  it "stops and resumes inheriting an attribute" do
    expect(page).to have_text("Assignee")
    expect_toggle("assignee", pressed: true)

    toggle_for("assignee").click

    expect_toggle("assignee", pressed: false)
    expect(link.reload.excluded_elements).to eq(%w[assignee])

    # The row stays listed so the switch remains reachable: the page shows the source's
    # configuration annotated with this variant's choices, not the resulting form.
    refresh

    expect(page).to have_text("Assignee")
    expect_toggle("assignee", pressed: false)
    expect_toggle("responsible", pressed: true)

    toggle_for("assignee").click

    expect_toggle("assignee", pressed: true)
    expect(link.reload.excluded_elements).to be_empty
  end
end
