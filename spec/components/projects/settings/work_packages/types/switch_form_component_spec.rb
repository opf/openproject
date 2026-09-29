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

RSpec.describe Projects::Settings::WorkPackages::Types::SwitchFormComponent,
               type: :component,
               with_flag: { type_variants: true } do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:base) { type.default_variant }
  shared_let(:global) { create(:type_variant, type:, variant_name: "Mobile") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }
  shared_let(:theirs) do
    create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Demo only")
  end

  current_user do
    create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] })
  end

  def render_form(source: base, selected: nil)
    render_inline(described_class.new(project:, source:, url: "/switch", **{ selected: }.compact))
  end

  it "offers the variants the project may use, in display order" do
    render_form

    expect(page).to have_select("Variant", options: [base, global, ours].map(&:composite_name))
  end

  it "offers no variant another project owns" do
    render_form

    expect(page).to have_no_css("option", text: "Demo only")
  end

  it "opens on the variant it is given" do
    render_form(selected: ours)

    expect(page).to have_select("Variant", selected: ours.composite_name)
  end

  it "opens on the variant in force when it is given none" do
    render_form

    expect(page).to have_select("Variant", selected: base.composite_name)
  end

  context "when the reader may not switch" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "offers nothing" do
      render_form

      expect(page).to have_select("Variant", options: [])
    end
  end
end
