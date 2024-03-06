#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.shared_context 'with a project with an arrangement of custom fields' do
  shared_let(:version_cf) { create(:version_project_custom_field, position: 1) }
  shared_let(:bool_cf) { create(:boolean_project_custom_field, position: 2) }
  shared_let(:user_cf) { create(:user_project_custom_field, position: 3) }
  shared_let(:int_cf) { create(:integer_project_custom_field, position: 4) }
  shared_let(:float_cf) { create(:float_project_custom_field, position: 5) }
  shared_let(:text_cf) { create(:text_project_custom_field, position: 6) }
  shared_let(:string_cf) { create(:string_project_custom_field, position: 7) }
  shared_let(:date_cf) { create(:date_project_custom_field, position: 8) }

  shared_let(:system_version) { create(:version, sharing: 'system') }

  shared_let(:role) do
    create(:project_role)
  end

  shared_let(:other_user) do
    create(:user,
           firstname: 'Other',
           lastname: 'User')
  end

  shared_let(:project) do
    create(:project,
           status_code: 'off_track',
           status_explanation: 'some explanation',
           members: { other_user => role }).tap do |p|
      p.description = "The description of the project"
      p.send(int_cf.attribute_setter, 5)
      p.send(bool_cf.attribute_setter, true)
      p.send(version_cf.attribute_setter, system_version)
      p.send(float_cf.attribute_setter, 4.5)
      p.send(text_cf.attribute_setter, 'Some **long** text')
      p.send(string_cf.attribute_setter, 'Some small text')
      p.send(date_cf.attribute_setter, Time.zone.today)
      p.send(user_cf.attribute_setter, other_user)

      p.save!(validate: false)
    end
  end
end

RSpec.shared_context 'with an instance of the described exporter' do
  before do
    login_as current_user
  end

  let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i(view_projects) })
  end
  let(:query_columns) { %w[name description project_status public] }
  let(:query) do
    build_stubbed(:project_query, select: query_columns)
  end
  let(:instance) do
    described_class.new(query)
  end

  let(:custom_fields) { project.available_custom_fields }

  let(:output) do
    instance.export!.content
  end
end
