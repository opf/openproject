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

RSpec.describe "Wysiwyg markdown source mode", :js do
  current_user { create(:admin) }

  let(:project) { create(:project, :with_internal_wiki) }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    visit project_wiki_path(project, :wiki)
  end

  it "can switch to markdown source and back" do
    editor.click_and_type_slowly "some text"

    editor.click_toolbar_button "Switch to Markdown source"

    expect(editor.container).to have_css(".ck-editor__source .CodeMirror", text: "some text")
    expect(editor.container).to have_css(".ck-button.ck-disabled", visible: :all, text: "Bold")

    editor.click_toolbar_button "Switch to WYSIWYG editor"

    expect(editor.container).to have_no_css(".ck-editor__source")
    expect(editor.container).to have_no_css(".ck-button.ck-disabled", visible: :all, text: "Bold")
    expect(page).to have_no_text("An error occurred within CKEditor")
    editor.expect_button "Switch to Markdown source"
    editor.expect_include_value "some text"
  end
end
