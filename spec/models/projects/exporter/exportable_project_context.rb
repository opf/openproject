#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

shared_context 'with a project with an arrangement of custom fields' do
  shared_let(:version_cf) { FactoryBot.create(:version_project_custom_field) }
  shared_let(:bool_cf) { FactoryBot.create(:bool_project_custom_field) }
  shared_let(:user_cf) { FactoryBot.create(:user_project_custom_field) }
  shared_let(:int_cf) { FactoryBot.create(:int_project_custom_field) }
  shared_let(:float_cf) { FactoryBot.create(:float_project_custom_field) }
  shared_let(:text_cf) { FactoryBot.create(:text_project_custom_field) }
  shared_let(:string_cf) { FactoryBot.create(:string_project_custom_field) }
  shared_let(:date_cf) { FactoryBot.create(:date_project_custom_field) }

  shared_let(:system_version) { FactoryBot.create(:version, sharing: 'system') }

  shared_let(:role) do
    FactoryBot.create(:role)
  end

  shared_let(:other_user) do
    FactoryBot.create(:user,
                      firstname: 'Other',
                      lastname: 'User')
  end

  shared_let(:project) do
    FactoryBot.create(:project, members: { other_user => role }).tap do |p|
      p.send(:"custom_field_#{int_cf.id}=", 5)
      p.send(:"custom_field_#{bool_cf.id}=", true)
      p.send(:"custom_field_#{version_cf.id}=", system_version)
      p.send(:"custom_field_#{float_cf.id}=", 4.5)
      p.send(:"custom_field_#{text_cf.id}=", 'Some **long** text')
      p.send(:"custom_field_#{string_cf.id}=", 'Some small text')
      p.send(:"custom_field_#{date_cf.id}=", Date.today)
      p.send(:"custom_field_#{user_cf.id}=", other_user)

      p.build_status(code: :off_track)

      p.save!(validate: false)
    end
  end
end

shared_context 'with an instance of the described exporter' do
  before do
    login_as current_user
  end

  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i(view_projects))
  end
  let(:query) { Queries::Projects::ProjectQuery.new }
  let(:instance) do
    described_class.new(query)
  end

  let(:custom_fields) { project.available_custom_fields }

  let(:output) do
    data = ''

    instance.export! do |result|
      data = result.content
    end

    data
  end
end
