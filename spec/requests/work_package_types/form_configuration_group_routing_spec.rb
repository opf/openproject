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

# Regression test for a group whose name contains a period. Custom attribute
# group names are used verbatim as the route :key segment (see
# WorkPackageTypes::FormConfigurationGroups::UpdateService#rename_group), and
# Rails' default dynamic segment matcher excludes "." (it is reserved for the
# optional format extension), so an unconstrained route 404s on such names.
RSpec.describe "Work package type form configuration group routing",
               :skip_csrf,
               type: :rails_request,
               with_ee: %i[edit_attribute_groups] do
  shared_let(:admin) { create(:admin) }

  let(:type) do
    create(:type).tap do |t|
      t.update_column(:attribute_groups, [["My.Group", %w[priority]]])
    end
  end

  before { login_as admin }

  it "resolves GET edit for a group whose name contains a period" do
    get edit_type_form_configuration_group_path(type_id: type.id, key: "My.Group"), as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end

  it "resolves PATCH update (rename) for a group whose name contains a period" do
    patch type_form_configuration_group_path(type_id: type.id, key: "My.Group"),
          params: { group: { name: "My.Group renamed" } },
          as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(type.reload.attribute_groups.map(&:key)).to eq(["My.Group renamed"])
  end

  it "resolves POST cancel_edit for a group whose name contains a period" do
    post cancel_edit_type_form_configuration_group_path(type_id: type.id, key: "My.Group"), as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end

  it "resolves DELETE destroy for a group whose name contains a period" do
    type.update_column(:attribute_groups, [
                         ["My.Group", %w[priority]],
                         [:details, %w[assignee]]
                       ])

    delete type_form_configuration_group_path(type_id: type.id, key: "My.Group"), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(type.reload.attribute_groups.map(&:key)).not_to include("My.Group")
  end
end
