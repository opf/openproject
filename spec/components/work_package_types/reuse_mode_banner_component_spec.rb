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

RSpec.describe WorkPackageTypes::ReuseModeBannerComponent, type: :component, with_flag: { subtypes: true } do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:type, name: "Feature") }

  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

  subject(:component) { described_class.new(type:, aspect:) }

  context "when the subtypes feature is disabled", with_flag: { subtypes: false } do
    it "does not render" do
      render_inline(component)

      expect(page.text).to be_blank
    end
  end

  context "when the aspect is independent" do
    before { render_inline(component) }

    it "shows the independent state" do
      expect(page).to have_text("Independent mode")
      expect(page).to have_text("No settings are inherited")
    end

    it "links the copy action to the copy dialog" do
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{type_configuration_copy_dialog_path(type_id: type.id, aspect:)}']",
        text: "Copy from type"
      )
    end

    it "renders the switch action" do
      expect(page).to have_button("Switch to linked mode")
    end
  end

  context "when the aspect has no copy service" do
    let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

    it "keeps the copy action a no-op button" do
      render_inline(component)

      expect(page).to have_button("Copy from type")
      expect(page).to have_no_link("Copy from type")
    end
  end

  context "when the aspect is linked" do
    before do
      type.link!(aspect, source:)

      render_inline(component)
    end

    it "shows the linked state with a link to the source type" do
      expect(page).to have_text("Linked mode")
      expect(page).to have_link("Feature", href: edit_type_settings_path(type_id: source.id))
      expect(page).to have_no_text("(parent)")
    end

    it "renders the switch and source actions" do
      expect(page).to have_button("Change source type")
      expect(page).to have_button("Switch to independent mode")
    end
  end

  context "when the aspect is linked to the parent" do
    let(:subtype) { create(:type, parent: source) }

    subject(:component) { described_class.new(type: subtype, aspect:) }

    before do
      subtype.link!(aspect, source:)

      render_inline(component)
    end

    it "annotates the source as the parent" do
      expect(page).to have_link("Feature", href: edit_type_settings_path(type_id: source.id))
      expect(page).to have_text("(parent)")
    end
  end
end
