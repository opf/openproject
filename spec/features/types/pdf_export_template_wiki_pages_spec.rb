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

RSpec.describe "artifact PDF export wiki pages", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:provider) { create(:internal_wiki_provider) }
  shared_let(:project) { create(:project, name: "Arcanos") }
  shared_let(:wiki) { create(:wiki, project:) }
  shared_let(:legal_page) { create(:wiki_page, wiki:, title: "Legal information") }
  shared_let(:privacy_page) { create(:wiki_page, wiki:, title: "Data privacy") }

  let(:type) { create(:type) }
  let(:dialog) { "##{WorkPackages::Exports::Generate::Templates::WikiPagesFieldsComponent::DIALOG_ID}" }

  def settings = type.default_variant.reload.pdf_export_templates.settings_for("artefact")

  def ref(wiki_page) = "#{provider.id}:#{wiki_page.id}"

  def add_wiki_pages(*pages)
    pages.each { add_wiki_page(it) }
  end

  def add_wiki_page(wiki_page)
    find_test_selector("pdf-export-add-wiki-pages").click

    within(dialog) do
      # The wiki's sub-tree loads itself and expands, so there is nothing to click open.
      expect(page).to have_css("[role='treeitem'][data-node-id='page:#{wiki_page.id}']")
      find("[role='treeitem'][data-node-id='page:#{wiki_page.id}']").click
      click_link_or_button I18n.t(:button_add)
    end
  end

  def chips = "opce-draggable-autocompleter .op-draggable-autocomplete--item"

  def drag_chip(label, after:)
    source = find(chips, text: label)
    target = find(chips, text: after)
    width = target.native.rect.width
    # Just inside the target's trailing edge, which is what the horizontal axis reads as "after".
    offset_x = (width / 2) - [6, width / 4].min

    perform_native_drag(source:, target:, offset_x: offset_x.round)
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
  end

  def configure(*pages)
    type.default_variant.pdf_export_templates.update_settings("artefact", "wiki_pages" => pages.map { ref(it) })
    type.default_variant.save!
  end

  def expect_listed(*labels)
    expect(page).to have_css(chips, count: labels.size)
    labels.each_with_index do |label, index|
      expect(page).to have_css("#{chips}:nth-of-type(#{index + 1})", text: label)
    end
  end

  before do
    login_as(admin)
    visit edit_settings_type_pdf_export_template_path(type_id: type.id, id: "artefact")
  end

  it "warns that including a wiki page shares it with every reader of the artifact" do
    expect(page).to have_css(".Banner", text: /visible to everyone who can export/)
  end

  it "adds wiki pages through the dialog and persists them on save" do
    add_wiki_pages(legal_page, privacy_page)

    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy")

    click_link_or_button I18n.t(:button_save)
    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(settings[:wiki_pages]).to eq [ref(legal_page), ref(privacy_page)]

    visit edit_settings_type_pdf_export_template_path(type_id: type.id, id: "artefact")
    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy")
  end

  # Cuprite cannot deliver the native drag lifecycle the chips rely on.
  it "reorders the wiki pages by drag and drop", :selenium do
    configure(privacy_page, legal_page)
    visit edit_settings_type_pdf_export_template_path(type_id: type.id, id: "artefact")

    # The chips are rendered by an Angular custom element; wait for it before dragging.
    expect_listed("Arcanos: Data privacy", "Arcanos: Legal information")

    drag_chip("Arcanos: Data privacy", after: "Arcanos: Legal information")

    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy")

    click_link_or_button I18n.t(:button_save)
    expect(settings[:wiki_pages]).to eq [ref(legal_page), ref(privacy_page)]
  end

  it "does not add the same page twice" do
    add_wiki_pages(legal_page, privacy_page, legal_page)

    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy")
  end

  it "clears the setting when every page is removed" do
    add_wiki_pages(legal_page)
    click_link_or_button I18n.t(:button_save)
    expect(settings[:wiki_pages]).to eq [ref(legal_page)]

    visit edit_settings_type_pdf_export_template_path(type_id: type.id, id: "artefact")
    find("#{chips} .op-draggable-autocomplete--remove-item", match: :first).click
    expect_listed
    click_link_or_button I18n.t(:button_save)

    expect(settings).not_to have_key(:wiki_pages)
  end
end
