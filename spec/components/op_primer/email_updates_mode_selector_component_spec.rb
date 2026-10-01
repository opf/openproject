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

RSpec.describe OpPrimer::EmailUpdatesModeSelectorComponent, type: :component do
  let(:enabled) { true }
  let(:path) { "example.com" }
  let(:title) { "Title" }
  let(:enabled_description) { "Enabled description" }
  let(:disabled_description) { "Disabled description" }
  let(:alt_text) { "Alt text" }
  let(:show_button) { true }

  subject(:component) do
    described_class.new(
      enabled:,
      path:,
      title:,
      enabled_description:,
      disabled_description:,
      alt_text:,
      show_button:
    )
  end

  context "when enabled is true" do
    it "renders the enabled variant" do
      render_inline(component)

      expect(page).to have_css("h4", text: title)
      expect(page).to have_test_selector("email-updates-mode-selector", text: "Enabled.")
      expect(page).to have_test_selector("email-updates-mode-selector", text: enabled_description)
      expect(page).to have_css(".octicon-bell-slash")
      expect(page).to have_link("Disable", href: path)
      expect(page).not_to have_test_selector("email-updates-mode-selector", text: alt_text)
    end
  end

  context "when enabled is false" do
    let(:enabled) { false }

    it "renders the disabled variant" do
      render_inline(component)

      expect(page).to have_css("h4", text: title)
      expect(page).to have_test_selector("email-updates-mode-selector", text: "Disabled.")
      expect(page).to have_test_selector("email-updates-mode-selector", text: disabled_description)
      expect(page).to have_css(".octicon-bell")
      expect(page).to have_link("Enable", href: path)
      expect(page).not_to have_test_selector("email-updates-mode-selector", text: alt_text)
    end
  end

  context "when show_button is false" do
    let(:show_button) { false }

    it "renders the version with alt_text" do
      render_inline(component)

      expect(page).to have_css("h4", text: title)
      expect(page).to have_test_selector("email-updates-mode-selector", text: "Enabled.")
      expect(page).to have_test_selector("email-updates-mode-selector", text: enabled_description)
      expect(page).to have_no_css(".octicon-bell-slash")
      expect(page).to have_no_link("Disable", href: path)
      expect(page).to have_test_selector("email-updates-mode-selector", text: alt_text)
    end
  end

  context "when show_button is false but alt_text isn't provided" do
    let(:show_button) { false }
    let(:alt_text) { nil }

    it "throws an error" do
      expect { render_inline(component) }.to raise_error(ArgumentError)
    end
  end
end
