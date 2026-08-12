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

RSpec.shared_context "with a project with an arrangement of custom fields" do
  shared_let(:version_cf) { create(:version_project_custom_field, :has_comment, position: 1) }
  shared_let(:bool_cf) { create(:boolean_project_custom_field, position: 2) }
  shared_let(:user_cf) { create(:user_project_custom_field, position: 3) }
  shared_let(:int_cf) { create(:integer_project_custom_field, position: 4) }
  shared_let(:float_cf) { create(:float_project_custom_field, position: 5) }
  shared_let(:text_cf) { create(:text_project_custom_field, position: 6) }
  shared_let(:string_cf) { create(:string_project_custom_field, position: 7) }
  shared_let(:date_cf) { create(:date_project_custom_field, position: 8) }
  shared_let(:hidden_cf) { create(:string_project_custom_field, :admin_only, :has_comment, position: 9) }
  shared_let(:link_cf) { create(:link_project_custom_field, position: 10) }

  shared_let(:not_used_string_cf) { create(:string_project_custom_field, position: 11) }

  shared_let(:system_version) do
    create(
      :version,
      sharing: "system",
      project: build(:project, active: false) # marking inactive is the simplest way to remove it from query (for non-admin users)
    )
  end

  shared_let(:role) do
    create(:project_role)
  end

  shared_let(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User")
  end

  # project needs to be reevaluted before every example as the creation behaves differently from different user contexts
  # shared_let cannot be used here as it would create the project only once
  let!(:project) do
    build(
      :project,
      status_code: "off_track",
      status_explanation: "some explanation",
      members: { other_user => role },
      description: "The description of the project",
      custom_field_values: {
        int_cf.id => 5,
        bool_cf.id => true,
        version_cf.id => system_version,
        float_cf.id => 4.5,
        text_cf.id => "Some **long** text",
        string_cf.id => "Some small text",
        date_cf.id => Time.zone.today,
        user_cf.id => other_user.id,
        hidden_cf.id => "hidden",
        link_cf.id => "https://www.example.com"
      },
      custom_comments: {
        version_cf.id => "Comment visible to members",
        hidden_cf.id => "Comment visible to admins"
      }
    ).tap { it.save!(validate: false) }
  end
end

RSpec.shared_context "with an instance of the described exporter" do
  before do
    login_as current_user
  end

  let(:permissions) { %i(view_projects view_project_attributes export_projects) }

  let(:current_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let(:query_columns) { %w[name description project_status public] }
  let(:query) do
    build_stubbed(:project_query, select: query_columns)
  end
  let(:instance) do
    described_class.new(query)
  end

  let(:global_project_custom_fields) { ProjectCustomField.visible.order(:position) }
  let(:custom_fields_of_project) { project.available_custom_fields }

  let(:output) do
    instance.export!.content
  end
end
