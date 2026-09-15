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

require 'rails_helper'

RSpec.describe 'API v3 BIM Link Templates', type: :request do
  let(:user) { create(:user, global_permissions: [:manage_ifc_models]) }
  let(:project) { create(:project) }
  let!(:template) do
    create(:bim_link_template,
           name: 'Structural Defects',
           project: project,
           author: user)
  end

  before do
    login_as(user)
  end

  describe 'GET /api/v3/bim/link_templates' do
    it 'returns all templates' do
      get '/api/v3/bim/link_templates'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('Collection')
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].size).to eq(1)
      expect(json['_embedded']['elements'].first['name']).to eq('Structural Defects')
    end

    it 'filters by project_id' do
      other_project = create(:project)
      create(:bim_link_template, name: 'Other Template', project: other_project, author: user)

      get "/api/v3/bim/link_templates?project_id=#{project.id}"

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['name']).to eq('Structural Defects')
    end

    it 'filters by relationship_type' do
      create(:bim_link_template, :responsible_for, name: 'Maintenance Tasks', project: project, author: user)

      get '/api/v3/bim/link_templates?relationship_type=affected_by'

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['relationship_type']).to eq('affected_by')
    end

    it 'filters by public' do
      create(:bim_link_template, :public_template, name: 'Public Template', author: user)

      get '/api/v3/bim/link_templates?public=true'

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['public']).to be true
    end

    it 'filters by auto_apply' do
      create(:bim_link_template, :auto_apply, name: 'Auto Template', project: project, author: user)

      get '/api/v3/bim/link_templates?auto_apply=true'

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['auto_apply']).to be true
    end
  end

  describe 'GET /api/v3/bim/link_templates/:id' do
    it 'returns a single template with details' do
      get "/api/v3/bim/link_templates/#{template.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('LinkTemplate')
      expect(json['id']).to eq(template.id)
      expect(json['name']).to eq('Structural Defects')
      expect(json['element_filters']).to be_present
      expect(json['_links']['author']).to be_present
      expect(json['_links']['statistics']).to be_present
      expect(json['_links']['clone']).to be_present
    end

    it 'returns 404 for non-existent template' do
      get '/api/v3/bim/link_templates/99999'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v3/bim/link_templates' do
    let(:valid_params) do
      {
        link_template: {
          name: 'HVAC Issues',
          description: 'Template for HVAC-related issues',
          relationship_type: 'affected_by',
          element_filters: {
            'types' => ['IfcDuctSegment', 'IfcAirTerminal']
          },
          auto_apply: false,
          public: false,
          project_id: project.id
        }
      }
    end

    it 'creates a new template' do
      expect do
        post '/api/v3/bim/link_templates', params: valid_params
      end.to change(Bim::LinkTemplate, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('HVAC Issues')
      expect(json['element_filters']['types']).to contain_exactly('IfcDuctSegment', 'IfcAirTerminal')
    end

    it 'sets author to current user' do
      post '/api/v3/bim/link_templates', params: valid_params

      template = Bim::LinkTemplate.last
      expect(template.author).to eq(user)
    end

    it 'returns 422 for invalid params' do
      invalid_params = { link_template: { name: '' } }

      post '/api/v3/bim/link_templates', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('Error')
    end

    it 'validates element_filters structure' do
      invalid_params = valid_params.deep_merge(
        link_template: {
          element_filters: {
            'invalid_key' => ['value']
          }
        }
      )

      post '/api/v3/bim/link_templates', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects public templates with project_id' do
      invalid_params = valid_params.deep_merge(
        link_template: {
          public: true,
          project_id: project.id
        }
      )

      post '/api/v3/bim/link_templates', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Public templates cannot be project-specific')
    end
  end

  describe 'PATCH /api/v3/bim/link_templates/:id' do
    it 'updates a template' do
      patch "/api/v3/bim/link_templates/#{template.id}",
            params: {
              link_template: {
                description: 'Updated description',
                auto_apply: true
              }
            }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['description']).to eq('Updated description')
      expect(json['auto_apply']).to be true
      expect(template.reload.description).to eq('Updated description')
    end

    it 'updates element_filters' do
      patch "/api/v3/bim/link_templates/#{template.id}",
            params: {
              link_template: {
                element_filters: {
                  'types' => ['IfcWall', 'IfcColumn']
                }
              }
            }

      expect(response).to have_http_status(:ok)
      expect(template.reload.element_filters['types']).to contain_exactly('IfcWall', 'IfcColumn')
    end

    it 'returns 422 for invalid updates' do
      patch "/api/v3/bim/link_templates/#{template.id}",
            params: {
              link_template: {
                name: ''
              }
            }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v3/bim/link_templates/:id' do
    it 'deletes a template' do
      expect do
        delete "/api/v3/bim/link_templates/#{template.id}"
      end.to change(Bim::LinkTemplate, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent template' do
      delete '/api/v3/bim/link_templates/99999'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v3/bim/link_templates/:id/clone' do
    it 'clones a template with new name' do
      expect do
        post "/api/v3/bim/link_templates/#{template.id}/clone",
             params: {
               new_name: 'Cloned Template'
             }
      end.to change(Bim::LinkTemplate, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Cloned Template')
      expect(json['element_filters']).to eq(template.element_filters)
      expect(json['relationship_type']).to eq(template.relationship_type)
    end

    it 'applies modifications during cloning' do
      post "/api/v3/bim/link_templates/#{template.id}/clone",
           params: {
             new_name: 'Modified Clone',
             modifications: {
               description: 'New description',
               relationship_type: 'observes'
             }
           }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['description']).to eq('New description')
      expect(json['relationship_type']).to eq('observes')
    end

    it 'sets cloned template as private' do
      original = create(:bim_link_template, :public_template, author: user)

      post "/api/v3/bim/link_templates/#{original.id}/clone",
           params: { new_name: 'Private Clone' }

      json = JSON.parse(response.body)
      expect(json['public']).to be false
    end
  end

  describe 'GET /api/v3/bim/link_templates/:id/statistics' do
    let!(:link1) { create(:bim_element_link, template: template, status: :active) }
    let!(:link2) { create(:bim_element_link, template: template, status: :completed) }
    let!(:link3) { create(:bim_element_link, template: template, status: :archived) }

    it 'returns usage statistics' do
      get "/api/v3/bim/link_templates/#{template.id}/statistics"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('TemplateStatistics')
      expect(json['template_id']).to eq(template.id)
      expect(json['total_links']).to eq(3)
      expect(json['active_links']).to eq(1)
      expect(json['completed_links']).to eq(1)
      expect(json['archived_links']).to eq(1)
      expect(json['_links']['template']).to be_present
    end

    it 'counts distinct work packages' do
      wp1 = create(:work_package)
      wp2 = create(:work_package)
      create(:bim_element_link, template: template, work_package: wp1)
      create(:bim_element_link, template: template, work_package: wp1)
      create(:bim_element_link, template: template, work_package: wp2)

      get "/api/v3/bim/link_templates/#{template.id}/statistics"

      json = JSON.parse(response.body)
      expect(json['work_packages']).to eq(3) # link1, link2, link3 work packages + wp1, wp2 (different)
    end
  end

  context 'without proper permissions' do
    let(:unauthorized_user) { create(:user) }

    before do
      login_as(unauthorized_user)
    end

    it 'returns 403 for create' do
      post '/api/v3/bim/link_templates', params: {
        link_template: {
          name: 'New Template',
          relationship_type: 'affected_by',
          element_filters: {}
        }
      }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for update' do
      patch "/api/v3/bim/link_templates/#{template.id}",
            params: { link_template: { name: 'Updated' } }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for delete' do
      delete "/api/v3/bim/link_templates/#{template.id}"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
