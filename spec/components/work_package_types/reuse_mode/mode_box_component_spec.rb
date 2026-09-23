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

RSpec.describe WorkPackageTypes::ReuseMode::ModeBoxComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type) }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  subject(:component) { described_class.new(variant:, aspect:) }

  context "when the aspect is independent" do
    before { render_inline(component) }

    it "shows the independent state" do
      expect(page).to have_text("Manual configuration")
      expect(page).to have_text("No settings are inherited")
    end

    it "keeps the neutral scheme" do
      expect(page).to have_css(".color-bg-inset")
      expect(page).to have_no_css(".color-bg-accent")
    end

    it "links the copy action to the copy dialog" do
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{type_configuration_copy_dialog_path(**variant.path_args, aspect:)}']",
        text: "Copy from another type"
      )
    end

    it "links the switch action to the inheritance dialog" do
      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{type_configuration_link_dialog_path(**variant.path_args, aspect:)}']",
        text: "Inherit from parent"
      )
    end
  end

  context "when the aspect has no copy service" do
    before do
      allow(WorkPackageTypes::CopyConfiguration).to receive(:supported?).with(aspect).and_return(false)
    end

    it "does not render the copy action" do
      render_inline(component)

      expect(page).to have_no_text("Copy from another type")
    end
  end

  context "when the aspect is linked to its base" do
    before do
      link_configuration(variant, aspect:)

      render_inline(component)
    end

    it "marks the linked state with the info scheme" do
      expect(page).to have_css(".color-bg-accent.color-border-accent")
    end

    it "shows the linked state with a link to the parent" do
      expect(page).to have_text("Inherited configuration")
      expect(page).to have_link(
        type.name,
        href: edit_type_form_configuration_path(type_id: type.id, variant_id: type.default_variant.id)
      )
    end

    it "breaks the source link out of the reloadable configuration frame" do
      expect(page).to have_css("a[data-turbo-frame='_top']", text: type.name)
    end

    it "links the switch-to-independent action to its dialog" do
      independence_path = type_configuration_independence_dialog_path(**variant.path_args, aspect:)

      expect(page).to have_css(
        "a[data-controller='async-dialog'][href='#{independence_path}']",
        text: "Configure manually"
      )
    end
  end
end
