#-- encoding: UTF-8

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

require 'spec_helper'

describe Projects::Exports::CSV, 'integration', type: :model do
  before do
    login_as current_user
  end

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

      p.save!(validate: false)
    end
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

  let(:parsed) do
    CSV.parse(output)
  end

  let(:header) { parsed.first }

  let(:rows) { parsed.drop(1) }

  it 'performs a successful export' do
    expect(parsed.size).to eq(2)
    expect(parsed.last).to eq [project.id.to_s, project.identifier, project.name, '', 'false']
  end

  describe 'custom field columns selected' do
    before do
      Setting.enabled_projects_columns += custom_fields.map { |cf| "cf_#{cf.id}" }
    end

    context 'when ee enabled', with_ee: %i[custom_fields_in_projects_list] do
      it 'renders all those columns' do
        expect(parsed.size).to eq 2

        cf_names = custom_fields.map(&:name)
        expect(header).to eq ['id', 'Identifier', 'Name', 'Status', 'Public', *cf_names]

        custom_values = custom_fields.map { |cf| project.formatted_custom_value_for(cf) }
        expect(rows.first)
          .to eq [project.id.to_s, project.identifier, project.name, '', 'false', *custom_values]
      end
    end

    context 'when ee not enabled' do
      it 'renders only the default columns' do
        expect(header).to eq %w[id Identifier Name Status Public]
      end
    end
  end

  context 'with no project visible' do
    let(:current_user) { User.anonymous }

    it 'does not include the project' do
      expect(output).not_to include project.identifier
      expect(parsed.size).to eq(1)
    end
  end
end
