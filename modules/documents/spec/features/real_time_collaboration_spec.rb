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
require_module_spec_helper

RSpec.describe "Real-time collaboration with Hocuspocus for documents",
               :js,
               :selenium,
               with_settings: { real_time_text_collaboration_enabled: true } do
  let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }
  let(:admin) { create(:admin, firstname: "Armin", lastname: "Admin") }
  let(:member_role) { create(:existing_project_role, permissions: [:view_documents]) }
  let(:readonly_user) { create(:user, member_with_roles: { project => member_role }, firstname: "Rita", lastname: "Readonly") }
  let(:project) { create(:project) }
  let(:document) { create(:document, :collaborative, project:) }

  context "with hocuspocus server" do
    include_context "with hocuspocus"

    context "with write permission" do
      before do
        login_as(admin)
      end

      it "shows the editor" do
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")
        expect(page).to have_no_content("Armin Admin")
        page.find_link("1 active editor").click
        expect(page).to have_content("Armin Admin")
      end

      it "renders a collaborative document and saves changes to the database" do
        visit document_path(document)
        expect(document.content_binary).to be_nil
        expect(page).to have_test_selector("blocknote-document-description")

        editor.fill_in("Hello Hocuspocus")
        wait_for { document.reload.content_binary }.to be_present
        expect(document.description).to eq("Hello Hocuspocus\n")
      end
    end

    context "with readonly permission" do
      before do
        login_as(readonly_user)
      end

      it "shows the editor but does not accept writes" do
        # rubocop:disable Layout/LineLength
        binary = "ARL108iNDAAHAQ5kb2N1bWVudC1zdG9yZQMKYmxvY2tHcm91cAcA9dPIjQwAAw5ibG9ja0NvbnRhaW5lcgcA9dPIjQwBAwlwYXJhZ3JhcGgHAPXTyI0MAgYEAPXTyI0MAwFIKAD108iNDAIPYmFja2dyb3VuZENvbG9yAXcHZGVmYXVsdCgA9dPIjQwCCXRleHRDb2xvcgF3B2RlZmF1bHQoAPXTyI0MAg10ZXh0QWxpZ25tZW50AXcEbGVmdCgA9dPIjQwBAmlkAXcOaW5pdGlhbEJsb2NrSWSH9dPIjQwBAw5ibG9ja0NvbnRhaW5lcgcA9dPIjQwJAwlwYXJhZ3JhcGgoAPXTyI0MCg9iYWNrZ3JvdW5kQ29sb3IBdwdkZWZhdWx0KAD108iNDAoJdGV4dENvbG9yAXcHZGVmYXVsdCgA9dPIjQwKDXRleHRBbGlnbm1lbnQBdwRsZWZ0KAD108iNDAkCaWQBdyQ4OTc0Yzk0YS1kZWZiLTRmMjEtYTc4Yi1mN2MyZTg5ZjUxZmKE9dPIjQwEBGVsbG+B9dPIjQwSAYT108iNDBMLIEhvY3VzcG9jdXMB9dPIjQwBEwE="
        # rubocop:enable Layout/LineLength
        document.update!(content_binary: binary, description: "Hello Hocuspocus\n")
        visit document_path(document)
        expect(page).to have_test_selector("blocknote-document-description")
        wait_for { editor.content }.to have_content("Hello Hocuspocus")
        editor.fill_in("Nothing changes")
        # Hocuspocus takes some time before saving. It's hard to wait for
        # something to not change, so this sleeps, although it's bad to do that in tests.
        sleep 5 # rubocop:disable OpenProject/NoSleepInFeatureSpecs
        expect(document.reload.content_binary).to eql(binary) # nothing changed
        expect(document.description).to eq("Hello Hocuspocus\n")
      end
    end
  end

  context "when in offline mode (without a connection to the hocuspocus server)" do
    # No Hocuspocus server is started here. On the first visit there is no
    # local cache, so the editor is blocked entirely to prevent an empty
    # Y.Doc from being synced as authoritative state on reconnect.
    shared_examples "a blocked offline editor" do
      it "blocks the editor and shows a server-unavailable message" do
        visit document_path(document)

        expect(page).to have_css(
          "[data-test-selector='connection-error-notice']",
          text: "Unable to open document because the real-time text collaboration server " \
                "is unreachable. Please contact the administrator if the problem persists.",
          wait: 10
        )
        expect(page).to have_no_test_selector("blocknote-document-description", wait: 0)
        expect(page).to have_test_selector("document-info-line", text: "You are currently offline.")
      end
    end

    context "with write permission" do
      before { login_as(admin) }

      it_behaves_like "a blocked offline editor"
    end

    context "with readonly permission" do
      before { login_as(readonly_user) }

      it_behaves_like "a blocked offline editor"
    end
  end
end
