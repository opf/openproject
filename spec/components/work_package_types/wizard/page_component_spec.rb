# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe WorkPackageTypes::Wizard::PageComponent, type: :component, with_flag: { type_variants: true } do
  let(:parent) { create(:type, name: "Phase") }
  let(:type) { create(:type) }

  before do
    login_as(create(:admin))
    type.link!(Type::ConfigurationLink::PDF_EXPORT, source: parent)
  end

  it "shows the linked PDF banner on the pdf step" do
    render_inline(described_class.new(type:, current_step: :pdf))

    expect(page).to have_text("Linked mode")
    expect(page).to have_text("Phase")
  end

  describe "breadcrumbs" do
    it "links the parent the variant is being created under" do
      render_inline(described_class.new(type: build(:type, parent:), current_step: :details))

      expect(page).to have_link("Phase",
                                href: Rails.application.routes.url_helpers.edit_type_details_path(type_id: parent.id))
    end

    it "omits the parent crumb when there is none" do
      render_inline(described_class.new(type: build(:type), current_step: :details))

      expect(page).to have_no_link("Phase")
    end
  end
end
