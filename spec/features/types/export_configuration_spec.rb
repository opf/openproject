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

RSpec.describe "type export configuration tab", :js do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  let!(:project) { create(:project, types: [type]) }

  before do
    login_as(admin)
    visit edit_type_pdf_export_template_index_path(type)
  end

  def within_pdf_export_template_container(template, &)
    within_test_selector("pdf-export-template-row-#{template.id}", &)
  end

  def toggle_pdf_export_template(template)
    find(:button, accessible_name: toggle_pdf_export_template_label(template)).click
  end

  def expect_checked_state(template)
    expect(page).to have_button(
      accessible_name: toggle_pdf_export_template_label(template),
      aria: { pressed: true }
    )
  end

  def expect_unchecked_state(template)
    expect(page).to have_button(
      accessible_name: toggle_pdf_export_template_label(template),
      aria: { pressed: false }
    )
  end

  def toggle_pdf_export_template_label(template)
    I18n.t(
      "types.edit.export_configuration.pdf_export_templates.actions.label_toggle_template",
      template: template.label
    )
  end

  it "disables/enables all" do
    click_link(I18n.t("types.edit.export_configuration.pdf_export_templates.actions.label_disable_all"))
    wait_for_reload
    variant.reload
    expect(variant.pdf_export_templates.list_enabled.length).to eq(0)
    click_link(I18n.t("types.edit.export_configuration.pdf_export_templates.actions.label_enable_all"))
    wait_for_reload
    variant.reload
    expect(variant.pdf_export_templates.list_enabled.length).to eq(variant.pdf_export_templates.list.length)
  end

  it "disables/enables one" do
    first = variant.pdf_export_templates.list_enabled.first
    within_pdf_export_template_container(first) do
      expect_checked_state(first)
      toggle_pdf_export_template(first)
      expect_unchecked_state(first)
      wait_for_reload
      variant.reload
      expect(variant.pdf_export_templates.list.first.enabled).to be(false)
      toggle_pdf_export_template(first)
      expect_checked_state(first)
      wait_for_reload
      variant.reload
      expect(variant.pdf_export_templates.list.first.enabled).to be(true)
    end
  end

  it "reorders by drag and drop" do
    first_id = variant.pdf_export_templates.list_enabled.first.id
    second_id = variant.pdf_export_templates.list_enabled[1].id
    Pages::Page.new.drag_and_drop_list(
      from: 0,
      to: 1,
      elements: "[data-test-selector^='pdf-export-template-row-']",
      handler: ".DragHandle"
    )
    wait_for_network_idle

    variant.reload
    expect(variant.pdf_export_templates.list[1].id).to eq(first_id)
    expect(variant.pdf_export_templates.list.first.id).to eq(second_id)
  end
end
