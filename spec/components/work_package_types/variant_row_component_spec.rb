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

RSpec.describe WorkPackageTypes::VariantRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  subject(:rendered_component) { render_inline(described_class.new(variant:, caption:)) }

  let(:caption) { nil }

  it "links the variant to its settings page" do
    expect(rendered_component)
      .to have_link("Hardware", href: edit_type_details_path(type_id: type.id, variant_id: variant.id))
  end

  it "leaves out the caption unless one is given" do
    expect(rendered_component).to have_no_text(I18n.t("types.index.variant_label"))
  end

  it "says nothing about new projects while the variant is not the one they start with" do
    expect(rendered_component).to have_no_text(I18n.t("types.index.enabled_in_new_projects"))
  end

  context "with a caption" do
    let(:caption) { I18n.t("types.index.variant_label") }

    it "renders it next to the name" do
      expect(rendered_component).to have_text(caption)
    end
  end

  context "when new projects start with this variant" do
    before { variant.update!(enabled_in_new_projects: true) }

    it "labels the row" do
      expect(rendered_component).to have_text(I18n.t("types.index.enabled_in_new_projects"))
    end
  end
end
