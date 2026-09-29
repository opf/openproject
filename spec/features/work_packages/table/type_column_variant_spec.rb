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

require "spec_helper"

RSpec.describe "Type shown in the work package table type column when a variant applies", :js,
               with_flag: { type_variants: true } do
  let(:user) { create(:admin) }

  let(:root_type) { create(:type, name: "Task") }
  let(:variant) { create(:type_variant, type: root_type, variant_name: "Bug") }

  let(:project) { create(:project, types: [variant]) }
  let(:work_package) do
    create(:work_package, subject: "A variantd work package", type: root_type, project:)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w[id subject type]
    query.save!
    query
  end

  before do
    login_as(user)
    query
    work_package

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(work_package)
  end

  it "renders the type's name in the type column, not the variant's" do
    type_field = wp_table.edit_field(work_package, :type)

    type_field.expect_state_text(root_type.name.upcase)
    expect(type_field.display_element.text).not_to include(variant.variant_name.upcase)
  end
end
