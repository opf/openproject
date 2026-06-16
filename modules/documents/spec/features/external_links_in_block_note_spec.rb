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

RSpec.describe "External links in BlockNote editor",
               :js,
               :selenium,
               with_settings: { real_time_text_collaboration_enabled: true } do
  include_context "with hocuspocus"
  include FormFields::Primerized::BlockNoteEditorBrowserActions

  let(:admin) { create(:admin) }
  let(:document) { create(:document, :collaborative) }
  let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }

  shared_examples "does not freeze when pasting multiple external links" do
    it "does not freeze when pasting content with multiple external links" do
      editor.paste_links(
        { text: "Link One", url: "https://example.com/one" },
        { text: "Link Two", url: "https://example.org/two" },
        { text: "Link Three", url: "https://other-site.com/three" },
        { text: "Link Four", url: "https://fourth-domain.net/four" },
        { text: "Link Five", url: "https://fifth-place.io/five" }
      )

      editor.fill_in(" Still typing after paste")
      expect(editor.content).to include("Still typing after paste")
    end
  end

  before do
    login_as(admin)
    visit document_path(document)
  end

  it "editor remains interactive when external-link extensions are active" do
    expect(page).to have_test_selector("blocknote-document-description")
    editor.fill_in("Hello from the editor")
    expect(editor.content).to include("Hello from the editor")

    editor.element.send_keys(:enter)
    editor.fill_in("Still typing just fine")
    expect(editor.content).to include("Still typing just fine")
  end

  it "sets target and rel attributes on external links in the shadow DOM" do
    editor.paste_links(text: "Example Site", url: "https://example.com")

    link = editor.shadow_root.find("a[target='_blank']", text: "Example Site", wait: 5)
    expect(link[:rel]).to include("noopener")
    expect(link[:rel]).to include("noreferrer")
  end

  it "embeds the 'opens in new tab' hint inside external links for screen readers" do
    editor.paste_links(text: "Accessible Link", url: "https://example.com")

    # The hint is a ProseMirror widget decoration wrapped in the link mark, so
    # it is rendered as a sr-only child of the <a>. This makes it part of the
    # link's accessible name, which screen readers announce reliably even
    # inside contenteditable — unlike aria-describedby, which VoiceOver/NVDA
    # ignore in edit mode.
    link = editor.shadow_root.find("a[target='_blank']", text: "Accessible Link", wait: 5)
    hint = link.find("span.sr-only", visible: :all)
    # The widget text is prefixed with a separator (NBSP) so the link's
    # computed accessible name doesn't concatenate as "Accessible LinkOpen…".
    # We assert containment rather than equality so the separator detail
    # stays an implementation concern of the extension, not the spec.
    expect(hint.text(:all)).to include(I18n.t(:open_link_in_a_new_tab))
  end

  it_behaves_like "does not freeze when pasting multiple external links"

  it "leaves no orphan hint when a linked range is deleted in one transaction" do
    editor.paste_links(text: "Doomed Link", url: "https://example.com")
    link = editor.shadow_root.find("a[target='_blank']", text: "Doomed Link", wait: 5)
    expect(link).to have_css("span.sr-only", visible: :all)

    # Deleting an entire link must leave no orphan widget at the deletion
    # seam. The apply gate reseats the widget set on any range deletion, so
    # buildDecorations runs on the post-delete doc, finds no link, and emits
    # no widget. A regression here would render a phantom empty <a> hosting
    # the sr-only hint, and screen readers would announce a link to nowhere.
    select_text_in_external_link
    send_forward_delete

    expect(editor.element).to have_no_css("a[target='_blank']", visible: :all)
    expect(editor.element).to have_no_css("span.sr-only", visible: :all)
  end

  it "preserves the hint when text is deleted from the end of a surviving link" do
    editor.paste_links(text: "Trim Me Tail", url: "https://example.com/tail")
    link = editor.shadow_root.find("a[target='_blank']", text: "Trim Me Tail", wait: 5)
    expect(link).to have_css("span.sr-only", visible: :all)

    # Tail-deletion inside a link must leave exactly one hint at the new
    # link end. Mapping the existing widget through the deletion is unsafe:
    # PM treats the widget's position as deleted when it coincides with the
    # deletion's right edge. The apply gate's deletion rule reseats the
    # widget on the post-delete doc instead.
    select_text_in_external_link(start_offset: -4)
    send_forward_delete

    surviving = editor.shadow_root.find("a[target='_blank']", text: "Trim Me", wait: 5)
    hints = surviving.all("span.sr-only", visible: :all)
    expect(hints.size).to eq(1)
    expect(hints.first.text(:all)).to include(I18n.t(:open_link_in_a_new_tab))
  end

  it "does not rewrite internal links or attach the sr-only hint" do
    editor.paste_links(text: "Internal Link", url: root_url)

    link = editor.shadow_root.find("a", text: "Internal Link", wait: 5)
    expect(link.native.property("href")).not_to include("/external_redirect")
    # Internal links should not receive the "opens in new tab" hint.
    expect(link).to have_no_css("span.sr-only", visible: :all)
  end

  context "with capture enabled",
          with_ee: %i[capture_external_links],
          with_settings: {
            real_time_text_collaboration_enabled: true,
            capture_external_links: true
          } do
    # Note: running with DevTools open (non-headless) inflates page.windows count.
    # This test expects headless mode; run headless if window counts seem off.
    it "intercepts clicks on external links and redirects through /external_redirect" do
      editor.paste_links(text: "Captured Link", url: "https://example.com/page")

      link = editor.shadow_root.find("a[target='_blank']", text: "Captured Link", wait: 5)
      # href stays as original — not rewritten in the DOM
      expect(link.native.property("href")).to include("example.com/page")
      expect(link.native.property("href")).not_to include("/external_redirect")

      original_window = page.current_window
      link.click

      # Wait for exactly one new window to open, verifying no double-open from TipTap + our handler
      wait_for { page.windows.size }.to eq(2)

      new_window = (page.windows - [original_window]).first
      within_window new_window do
        expect(page.current_url).to include("/external_redirect")
      end
    ensure
      (page.windows - [original_window]).each do |w|
        w.close
      rescue StandardError
        # window may already have closed or the session may be gone
      end
    end

    it_behaves_like "does not freeze when pasting multiple external links"
  end
end
