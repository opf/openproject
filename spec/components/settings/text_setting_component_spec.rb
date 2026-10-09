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

RSpec.describe Settings::TextSettingComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) { render_component("fr", name: "emails_footer") }

  before do
    with_config(emails_footer: { "en" => "blah", "fr" => "bah" })
  end

  it "renders the language select" do
    expect(rendered_component).to have_select "lang-for-emails_footer",
                                              with_options: [
                                                "English",
                                                "Español",
                                                "Français",
                                                "Deutsch",
                                                "Українська",
                                                "简体中文"
                                              ],
                                              selected: "Français"
  end

  it "renders the hidden textarea" do
    expect(rendered_component).to have_field "Emails footer", type: "textarea", with: "bah"
  end

  it "renders the rich text area" do
    expect(rendered_component).to have_element "opce-ckeditor-augmented-textarea",
                                               "data-text-area-id": "settings-emails_footer".to_json
  end
end
