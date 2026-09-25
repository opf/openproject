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
  let(:source) { type.default_variant }

  subject(:component) { described_class.new(variant:, aspect:) }

  it "does not render for a base variant, which has no mode to choose" do
    render_inline(described_class.new(variant: type.default_variant, aspect:))

    expect(page).to have_no_text("Use the same settings as the type")
    expect(page).to have_no_text("Configure this page manually")
  end

  context "when the aspect is manual (not inherited)" do
    before { render_inline(component) }

    it "offers both modes with manual selected" do
      expect(page).to have_text("Use the same settings as the type")
      expect(page).to have_text("Configure this page manually")
      expect(page).to have_css("input[type=radio][value='manual'][checked]")
      expect(page).to have_no_css("input[type=radio][value='inherited'][checked]")
    end

    it "names the parent type in the inherit option, linking to that setting on it" do
      expect(page).to have_link(
        source.composite_name,
        href: edit_type_form_configuration_path(type_id: type.id, variant_id: source.id)
      )
    end

    it "breaks the parent link out of the reloadable configuration frame" do
      expect(page).to have_css("a[data-turbo-frame='_top']", text: source.composite_name)
    end

    it "wires each option to its switch dialog" do
      expect(page).to have_css(
        "input[value='inherited'][data-dialog-url='#{type_configuration_link_dialog_path(**variant.path_args, aspect:)}']"
      )
      expect(page).to have_css(
        "input[value='manual'][data-dialog-url='#{type_configuration_independence_dialog_path(**variant.path_args, aspect:)}']"
      )
    end
  end

  context "when the aspect is linked to its base" do
    before do
      link_configuration(variant, aspect:)

      render_inline(component)
    end

    it "selects the inherit option" do
      expect(page).to have_css("input[type=radio][value='inherited'][checked]")
      expect(page).to have_no_css("input[type=radio][value='manual'][checked]")
    end
  end
end
