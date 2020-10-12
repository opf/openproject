#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.

require 'spec_helper'
require 'rack/test'

describe ::API::V3::TimeEntries::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { time_entry.project }
  let(:time_entry) { FactoryBot.create(:time_entry) }
  let(:active_activity) { FactoryBot.create(:time_entry_activity) }
  let(:in_project_inactive_activity) do
    FactoryBot.create(:time_entry_activity).tap do |tea|
      TimeEntryActivitiesProject.insert(project_id: project.id, activity_id: tea.id, active: false)
    end
  end
  let(:custom_field) { FactoryBot.create(:time_entry_custom_field) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:work_package) do
    FactoryBot.create(:work_package, project: project)
  end
  let(:other_user) { FactoryBot.create(:user) }
  let(:permissions) { %i[view_time_entries edit_time_entries view_work_packages] }

  let(:path) { api_v3_paths.time_entry_form(time_entry.id) }
  let(:parameters) { {} }

  before do
    login_as(user)

    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/time_entries/:id/form' do
    it 'returns 200 OK' do
      expect(response.status).to eq(200)
    end

    it 'returns a form' do
      expect(response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end

    context 'with all parameters' do
      let(:parameters) do
        {
          _links: {
            workPackage: {
              href: api_v3_paths.work_package(work_package.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
            activity: {
              href: api_v3_paths.time_entries_activity(active_activity.id)
            }
          },
          spentOn: Date.today.to_s,
          hours: 'PT5H',
          "comment": {
            raw: "some comment"
          },
          "customField#{custom_field.id}": {
            raw: 'some cf text'
          }
        }
      end

      it 'has 0 validation errors' do
        expect(subject.body).to have_json_size(0).at_path('_embedded/validationErrors')
      end

      it 'does not alter the entry' do
        expect(time_entry.work_package)
          .not_to eql work_package
      end

      it 'has the values prefilled in the payload' do
        body = subject.body

        expect(body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_embedded/payload/_links/project/href')

        expect(body)
          .to be_json_eql(api_v3_paths.work_package(work_package.id).to_json)
          .at_path('_embedded/payload/_links/workPackage/href')

        expect(body)
          .to be_json_eql(api_v3_paths.time_entries_activity(active_activity.id).to_json)
          .at_path('_embedded/payload/_links/activity/href')

        expect(body)
          .to be_json_eql("some comment".to_json)
          .at_path("_embedded/payload/comment/raw")

        expect(body)
          .to be_json_eql(Date.today.to_s.to_json)
          .at_path('_embedded/payload/spentOn')

        expect(body)
          .to be_json_eql("PT5H".to_json)
          .at_path('_embedded/payload/hours')

        expect(body)
          .to be_json_eql("some cf text".to_json)
          .at_path("_embedded/payload/customField#{custom_field.id}/raw")

        # As the user is always the current user, it is not part of the payload
        expect(body)
          .not_to have_json_path('_embedded/payload/_links/user')
      end

      it 'has the available values listed in the schema' do
        body = subject.body

        wp_path = api_v3_paths.time_entries_available_work_packages_on_edit(time_entry.id)

        expect(body)
          .to be_json_eql(wp_path.to_json)
          .at_path('_embedded/schema/workPackage/_links/allowedValues/href')

        expect(body)
          .to be_json_eql(api_v3_paths.time_entries_available_projects.to_json)
          .at_path('_embedded/schema/project/_links/allowedValues/href')
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.time_entry(time_entry.id).to_json)
          .at_path('_links/commit/href')
      end
    end

    context 'with an invalid parameter' do
      let(:parameters) do
        {
          _links: {
            workPackage: {
              href: api_v3_paths.work_package(0)
            }
          }
        }
      end

      it 'has 1 validation errors' do
        expect(subject.body).to have_json_size(1).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on workPackage' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/workPackage')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit/href')
      end
    end

    context 'with permissions to edit own time entries' do
      let(:permissions) { %i[view_time_entries edit_own_time_entries] }

      context 'with the time_entry being of the user' do
        let(:user) do
          user = time_entry.user

          FactoryBot.create(:member,
                            project: time_entry.project,
                            roles: [FactoryBot.create(:role, permissions: permissions)],
                            principal: user)

          user
        end

        it 'returns 200 OK' do
          expect(response.status).to eq(200)
        end
      end

      context 'with the time_entry being of a different user' do
        it 'returns 403 Not Authorized' do
          expect(response.status).to eq(403)
        end
      end
    end

    context 'without the necessary permission' do
      let(:permissions) { %i[view_time_entries] }

      it 'returns 403 Not Authorized' do
        expect(response.status).to eq(403)
      end
    end
  end
end
