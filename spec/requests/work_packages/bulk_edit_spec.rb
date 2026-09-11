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

RSpec.describe "Bulk editing work packages across projects", type: :rails_request do
  shared_let(:type) { create(:type) }
  shared_let(:everywhere) { create(:integer_wp_custom_field, name: "Shared everywhere") }
  shared_let(:only_here) { create(:integer_wp_custom_field, name: "Only in one") }

  shared_let(:narrow) { create(:project, types: [type]) }
  shared_let(:wide) { create(:project, types: [type]) }

  shared_let(:user) do
    create(:user, member_with_permissions: { narrow => %i[view_work_packages edit_work_packages],
                                             wide => %i[view_work_packages edit_work_packages] })
  end

  shared_let(:in_narrow) { create(:work_package, project: narrow, type:) }
  shared_let(:in_wide) { create(:work_package, project: wide, type:) }

  before do
    base = type.default_variant
    base.custom_field_ids = [everywhere.id, only_here.id]
    base.attribute_groups = [["Details", [everywhere.attribute_name, only_here.attribute_name]]]
    base.save!

    # The narrow project applies a variant that drops one of the two fields.
    variant = create(:type_variant, type:,
                                    form_configuration_source: base,
                                    form_configuration_excluded_elements: [only_here.attribute_name])
    ProjectType.find_by(project: narrow, type:).update!(variant:)

    login_as user
  end

  it "offers only the custom fields every selected project shows" do
    get "/work_packages/bulk/edit", params: { ids: [in_narrow.id, in_wide.id] }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Shared everywhere")
    expect(response.body).not_to include("Only in one")
  end

  it "offers a field that the single selected project shows" do
    get "/work_packages/bulk/edit", params: { ids: [in_wide.id] }

    expect(response.body).to include("Shared everywhere")
    expect(response.body).to include("Only in one")
  end
end
