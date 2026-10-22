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

require "rails_helper"

RSpec.describe "Links to headings in BlockNote editor",
               :js,
               :selenium,
               with_settings: { real_time_text_collaboration_enabled: true } do
  include_context "with hocuspocus"

  let(:admin) { create(:admin) }
  let(:document) { create(:document, :collaborative) }
  let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }

  # Headless browsers may refuse the clipboard, so the spec records what would be written.
  def record_clipboard
    page.execute_script(<<~JS)
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: (text) => { window.copiedText = text; return Promise.resolve(); } }
      });
    JS
  end

  before do
    login_as(admin)
    visit document_path(document)
    editor.element
  end

  it "copies a link to a heading" do
    editor.fill_in("# Introduction")
    record_clipboard

    editor.shadow_root.find("[data-content-type='heading']", text: "Introduction").hover
    editor.shadow_root.find("button[title='#{I18n.t('js.button_copy_link_to_clipboard')}']").click

    expect(editor.shadow_root).to have_css("button[title='#{I18n.t('js.clipboard.copied_successful')}']")
    expect(page.evaluate_script("window.copiedText"))
      .to eq("#{page.current_url}#heading-#{editor.heading_block_id('Introduction')}")
  end

  it "opens a link to a heading at that heading" do
    editor.fill_in(Array.new(60) { ["Paragraph", :enter] }.flatten)
    editor.fill_in("# Far down")
    wait_for { document.reload.description }.to include("Far down")
    block_id = editor.heading_block_id("Far down")

    visit home_path
    visit document_path(document)
    wait_for { editor.content }.to include("Far down")
    expect(editor.heading_in_viewport?(block_id)).to be(false)

    visit home_path
    visit document_path(document, anchor: "heading-#{block_id}")

    wait_for { editor.heading_in_viewport?(block_id) }.to be(true)
    expect(page.current_url).to end_with("#heading-#{block_id}")
  end
end
