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
# See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Projects::Copy::CopyAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:text_custom_field) do
    create(:text_project_custom_field)
  end
  shared_let(:list_custom_field) do
    create(:list_project_custom_field)
  end

  shared_let(:source_project) do
    create :project,
                      enabled_module_names: %w[work_package_tracking wiki],
                      custom_field_values: {
                        text_custom_field.id => 'source text',
                        list_custom_field.id => list_custom_field.custom_options.last.id
                      }
  end

  shared_let(:work_package) { create :work_package, project: source_project }
  shared_let(:wiki_page) { create :wiki_page, wiki: source_project.wiki }

  shared_let(:current_user) do
    create :user,
                      member_in_project: source_project,
                      member_with_permissions: %i[copy_projects view_project view_work_packages]
  end

  let(:path) { api_v3_paths.project_copy(source_project.id) }
  let(:params) do
    {
    }
  end

  before do
    login_as(current_user)

    post path, params.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/projects/:id/copy' do
    describe 'with empty params' do
      it 'returns 422', :aggregate_failures do
        expect(response.status).to eq(422)

        expect(response.body)
          .to be_json_eql('Error'.to_json)
                .at_path('_type')

        expect(response.body)
          .to be_json_eql("Name can't be blank.".to_json)
                .at_path("message")
      end
    end

    describe 'with attributes given' do
      let(:params) do
        { name: 'My copied project',
          identifier: 'my-copied-project',
          "customField#{text_custom_field.id}": {
            "raw": "CF text"
          },
        }
      end

      it 'returns with a redirect to job' do

        aggregate_failures do
          expect(response.status).to eq(302)

          expect(response).to be_redirect

          expect(response.location).to match /\/api\/v3\/job_statuses\/[\w-]+\z/
        end

        get response.location

        expect(last_response.status).to eq 200

        expect(last_response.body)
          .to be_json_eql('in_queue'.to_json)
                .at_path("status")

        perform_enqueued_jobs

        get response.location

        expect(last_response.status).to eq 200

        expect(last_response.body)
          .to be_json_eql('success'.to_json)
                .at_path("status")

        expect(last_response.body)
          .to be_json_eql("Created project My copied project".to_json)
                .at_path("message")

        project = Project.find_by(identifier: 'my-copied-project')
        expect(project).to be_present

        expect(project.custom_value_for(text_custom_field).value).to eq 'CF text'
        expect(project.custom_value_for(list_custom_field).formatted_value).to eq list_custom_field.custom_options.last.value
      end
    end

    describe 'with restricted copying' do
      let(:params) do
        { name: 'My copied project',
          identifier: 'my-copied-project',
          _meta: {
            copyWorkPackages: true,
            copyWiki: false,
          }
        }
      end

      it 'does not copy the wiki' do
        perform_enqueued_jobs

        project = Project.find_by(identifier: 'my-copied-project')
        expect(project).to be_present

        expect(source_project.wiki.pages.count).to eq 1
        expect(project.wiki.pages.count).to eq 0

        expect(source_project.work_packages.count).to eq 1
        expect(project.work_packages.count).to eq 1
      end
    end

    describe 'sendNotifications' do
      let(:params) do
        { name: 'My copied project',
          identifier: 'my-copied-project',
          _meta: {
            sendNotifications: sendNotifications
          }
        }
      end

      context 'when false' do
        let(:sendNotifications) { false }
        it 'queues the job without notifications' do
          expect(CopyProjectJob)
            .to have_been_enqueued.with do |args|
            expect(args[:send_mails]).to eq false
          end
        end
      end

      context 'when true' do
        let(:sendNotifications) { true }
        it 'queues the job with notifications' do
          expect(CopyProjectJob)
            .to have_been_enqueued.with do |args|
            expect(args[:send_mails]).to eq true
          end
        end
      end
    end

    context 'without the necessary permission' do
      let(:current_user) do
        create :user,
                          member_in_project: source_project,
                          member_with_permissions: %i[view_project view_work_packages]
      end

      it 'returns 403 Not Authorized' do
        expect(response.status).to eq(403)
      end
    end
  end
end
