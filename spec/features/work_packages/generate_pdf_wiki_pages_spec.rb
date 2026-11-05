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

require "spec_helper"
require "features/work_packages/work_packages_page"

RSpec.describe "work package generate PDF dialog, wiki pages", :js do
  shared_let(:user) { create(:admin) }
  shared_let(:download_list) { DownloadList.new }
  shared_let(:provider) { create(:internal_wiki_provider) }
  shared_let(:project) { create(:project, name: "Arcanos") }
  shared_let(:wiki) { create(:wiki, project:) }
  shared_let(:legal_page) { create(:wiki_page, wiki:, title: "Legal information") }
  shared_let(:privacy_page) { create(:wiki_page, wiki:, title: "Data privacy") }
  shared_let(:extra_page) { create(:wiki_page, wiki:, title: "Terms of use") }

  shared_let(:work_package) { create(:work_package, project:) }

  let(:exporter) { instance_double(WorkPackage::PDFExport::Artefact) }
  let(:submitted) { [] }

  def ref(wiki_page) = "#{provider.id}:#{wiki_page.id}"

  def chips = "opce-draggable-autocompleter .op-draggable-autocomplete--item"

  def dialog = "##{WorkPackages::Exports::Generate::Templates::WikiPagesFieldsComponent::DIALOG_ID}"

  def expect_listed(*labels)
    expect(page).to have_css(chips, count: labels.size)
    labels.each_with_index do |label, index|
      expect(page).to have_css("#{chips}:nth-of-type(#{index + 1})", text: label)
    end
  end

  def add_wiki_page(wiki_page)
    find_test_selector("pdf-export-add-wiki-pages").click

    within(dialog) do
      expect(page).to have_css("[role='treeitem'][data-node-id='page:#{wiki_page.id}']")
      find("[role='treeitem'][data-node-id='page:#{wiki_page.id}']").click
      click_link_or_button I18n.t(:button_add)
    end
  end

  def remove_chip(label)
    find(chips, text: label).find(".op-draggable-autocomplete--remove-item").click
  end

  def generate!
    click_link_or_button I18n.t("pdf_generator.dialog.submit")
    expect(download_list.refresh_from(page).latest_download.to_s).to have_text("filename.pdf")
  end

  before do
    allow(WorkPackage::PDFExport::Artefact).to receive(:new) do |_work_package, params|
      submitted.replace(Array(params[:wiki_pages]))
      exporter
    end
    allow(exporter).to receive(:export!).and_return(
      Exports::Result.new(format: :pdf, title: "filename.pdf", content: "PDF Content",
                          mime_type: "application/pdf")
    )

    variant = work_package.type_variant
    variant.pdf_export_templates.update_settings(
      "artefact", "wiki_pages" => [ref(legal_page), ref(privacy_page)]
    )
    variant.save!

    login_as(user)
    Pages::FullWorkPackage.new(work_package).visit!
    click_link_or_button "More"
    click_link_or_button "Generate PDF"
    wait_for_size_animation_completion("##{WorkPackages::Exports::Generate::ModalDialogComponent::MODAL_ID}")
    select I18n.t("pdf_generator.template_artefact.label"), from: "template"
  end

  after { DownloadList.clear }

  # The sentinel is what lets an emptied list clear the stored setting; it never survives
  # WikiPagesResolver.
  def submitted_refs = submitted - [""]

  it "prefills the configured pages in the configured order" do
    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy")

    generate!

    expect(submitted_refs).to eq [ref(legal_page), ref(privacy_page)]
  end

  it "lets the user drop a configured page from this one export" do
    remove_chip("Arcanos: Data privacy")
    expect_listed("Arcanos: Legal information")

    generate!

    expect(submitted_refs).to eq [ref(legal_page)]
    expect(work_package.type_variant.reload.pdf_export_templates.settings_for("artefact")[:wiki_pages])
      .to eq [ref(legal_page), ref(privacy_page)]
  end

  it "lets the user add a page of their own through the tree dialog" do
    add_wiki_page(extra_page)

    expect_listed("Arcanos: Legal information", "Arcanos: Data privacy", "Arcanos: Terms of use")

    generate!

    expect(submitted_refs).to eq [ref(legal_page), ref(privacy_page), ref(extra_page)]
  end
end
