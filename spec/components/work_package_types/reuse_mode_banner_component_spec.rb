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

RSpec.describe WorkPackageTypes::ReuseModeBannerComponent, type: :component, with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type) }
  shared_let(:source_type) { create(:type, name: "Feature") }
  shared_let(:source) { source_type.default_variant }
  shared_let(:variant) { type.default_variant }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  subject(:component) { described_class.new(variant:, aspect:) }

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
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
        "a[data-controller='async-dialog'][href='#{type_configuration_copy_dialog_path(**variant.path_args, aspect:)}']",
        text: "Copy from type"
      )
    end

    it "links the switch action to the linked mode dialog" do
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{type_configuration_link_dialog_path(**variant.path_args, aspect:)}']",
        text: "Switch to linked mode"
      )
    end
  end

  context "when the aspect has no copy service" do
    before do
      allow(WorkPackageTypes::CopyConfiguration).to receive(:supported?).with(aspect).and_return(false)
    end

    it "does not render the copy action" do
      render_inline(component)

      expect(page).to have_no_text("Copy from type")
    end
  end

  context "when the aspect is linked" do
    before do
      link_configuration(variant, source:, aspect:)

      render_inline(component)
    end

    it "shows the linked state with a link to the source variant" do
      expect(page).to have_text("Linked mode")
      expect(page).to have_link(
        "Feature",
        href: edit_type_form_configuration_path(type_id: source.type_id, variant_id: source.id)
      )
      expect(page).to have_no_text("(parent)")
    end

    it "breaks the source link out of the reloadable configuration frame" do
      expect(page).to have_css("a[data-turbo-frame='_top']", text: "Feature")
    end

    it "links the change-source and switch-to-independent actions to their dialogs" do
      link_path = type_configuration_link_dialog_path(**variant.path_args, aspect:)
      independence_path = type_configuration_independence_dialog_path(**variant.path_args, aspect:)

      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{link_path}']",
        text: "Change source type"
      )
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{independence_path}']",
        text: "Switch to independent mode"
      )
    end
  end

  context "when the aspect is linked to the type's base variant" do
    let(:named_variant) { create(:type_variant, type:, variant_name: "Hardware") }

    subject(:component) { described_class.new(variant: named_variant, aspect:) }

    before do
      link_configuration(named_variant, source: type.default_variant, aspect:)

      render_inline(component)
    end

    it "annotates the source as the parent" do
      expect(page).to have_link(
        type.name,
        href: edit_type_form_configuration_path(type_id: type.id, variant_id: type.default_variant.id)
      )
      expect(page).to have_text("(parent)")
    end
  end
end
