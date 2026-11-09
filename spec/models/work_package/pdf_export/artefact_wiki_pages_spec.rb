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

RSpec.describe WorkPackage::PDFExport::Artefact, "wiki pages" do
  include PDFExportSpecUtils

  shared_let(:provider) { create(:internal_wiki_provider) }
  shared_let(:type) { create(:type_bug) }
  shared_let(:status) { create(:status, name: "In progress", is_default: true) }
  shared_let(:project) { create(:project, name: "Artifact project", types: [type], public: true) }
  shared_let(:wiki) { create(:wiki, project:) }
  shared_let(:legal_page) { create(:wiki_page, wiki:, title: "Legal information", text: "The legal fineprint.") }
  shared_let(:privacy_page) { create(:wiki_page, wiki:, title: "Data privacy", text: "The privacy fineprint.") }

  shared_let(:work_package) do
    create(:work_package, project:, type:, status:, subject: "The artifact subject", description: "Description")
  end

  # Deliberately without view_wiki_pages: configuring a page is the grant.
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end

  let(:options) { {} }
  let(:exporter) { described_class.new(work_package, options) }

  subject(:pdf_text) do
    login_as(user)
    PDF::Inspector::Text.analyze(exporter.export!.content).strings.join(" ")
  end

  def ref(page) = "#{provider.id}:#{page.id}"

  def configure(*pages)
    variant = work_package.type_variant
    variant.pdf_export_templates.update_settings("artefact", "wiki_pages" => pages.map { ref(it) })
    variant.save!
  end

  it "renders nothing extra when no wiki page is configured" do
    expect(pdf_text).not_to include("Legal information")
  end

  context "with two configured pages" do
    before { configure(legal_page, privacy_page) }

    it "renders both titles and their content for a reader without wiki access" do
      expect(pdf_text).to include("Legal information", "The legal fineprint.")
      expect(pdf_text).to include("Data privacy", "The privacy fineprint.")
    end

    it "renders them in the configured order" do
      expect(pdf_text.index("The legal fineprint.")).to be < pdf_text.index("The privacy fineprint.")
    end

    it "lists them in the table of contents" do
      entries = exporter.toc_entries.pluck(:key)

      expect(entries.last(2)).to eq ["wiki_page_#{legal_page.id}", "wiki_page_#{privacy_page.id}"]
    end

    context "when the export submits its own order" do
      let(:options) { { wiki_pages: [ref(privacy_page), ref(legal_page)] } }

      it "follows the submitted order" do
        expect(pdf_text.index("The privacy fineprint.")).to be < pdf_text.index("The legal fineprint.")
      end
    end

    context "when the export drops one of them" do
      let(:options) { { wiki_pages: [ref(legal_page)] } }

      it "omits the dropped page from this export only" do
        expect(pdf_text).to include("The legal fineprint.")
        expect(pdf_text).not_to include("The privacy fineprint.")
      end
    end

    context "when a configured page is deleted" do
      before { privacy_page.destroy }

      it "skips it silently" do
        expect(pdf_text).to include("The legal fineprint.")
        expect(pdf_text).not_to include("Data privacy")
      end
    end
  end

  context "with an image attached to a configured page" do
    shared_let(:attachment) { create(:attachment, container: legal_page, filename: "image.png") }

    before { configure(legal_page) }

    it "embeds it although the reader cannot open the wiki page itself" do
      login_as(user)

      expect(attachment.visible?(user)).to be false
      expect(exporter.send(:attachment_by_api_content_src, "/api/v3/attachments/#{attachment.id}/content"))
        .to eq attachment
    end

    it "still refuses an image attached to a page that is not configured" do
      other = create(:attachment, container: privacy_page, filename: "other.png")
      login_as(user)

      expect(exporter.send(:attachment_by_api_content_src, "/api/v3/attachments/#{other.id}/content")).to be_nil
    end
  end

  context "when the export forges a page the user may not read" do
    shared_let(:other_project) { create(:project, name: "Other") }
    shared_let(:other_wiki) { create(:wiki, project: other_project) }
    shared_let(:secret_page) { create(:wiki_page, wiki: other_wiki, title: "Secret", text: "Leaked fineprint.") }

    let(:options) { { wiki_pages: [ref(secret_page)] } }

    it "does not leak it" do
      expect(pdf_text).not_to include("Leaked fineprint.")
    end
  end
end
