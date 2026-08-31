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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::HierarchyListComponent,
               type: :component, with_ee: [:custom_field_hierarchies] do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:custom_field) { create(:project_custom_field, :hierarchy) }
  let(:attribute) { custom_field.attribute_name.to_sym }

  it "renders a placeholder when no value is set" do
    render_inline(described_class.new(model: project, attribute:, writable: false, truncated: false))

    expect(rendered_content).to have_text(I18n.t("placeholders.default"))
  end

  it "renders the item label for a single hierarchy value" do
    item = create(:hierarchy_item, label: "Alpha")
    create(:custom_value, :skip_validations, customized: project, custom_field:, value: item.id.to_s)

    render_inline(described_class.new(model: project, attribute:, writable: false, truncated: false))

    expect(rendered_content).to have_text("Alpha")
  end

  context "with a multi-value hierarchy field" do
    let(:custom_field) { create(:project_custom_field, :multi_hierarchy) }

    it "renders multiple item labels joined by comma" do
      item1 = create(:hierarchy_item, label: "Alpha")
      item2 = create(:hierarchy_item, label: "Beta")
      create(:custom_value, :skip_validations, customized: project, custom_field:, value: item1.id.to_s)
      create(:custom_value, :skip_validations, customized: project, custom_field:, value: item2.id.to_s)

      render_inline(described_class.new(model: project, attribute:, writable: false, truncated: false))

      expect(rendered_content).to have_text("Alpha, Beta")
    end
  end
end
