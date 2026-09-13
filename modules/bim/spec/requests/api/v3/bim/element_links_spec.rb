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

RSpec.describe 'API v3 BIM Element Links', type: :request do
  let(:user) { create(:user, global_permissions: [:manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project: project) }
  let(:ifc_model) { create(:ifc_model, :with_xkt_attachment, project: project) }
  let!(:element_link) do
    create(:bim_element_link,
           work_package: work_package,
           ifc_model: ifc_model,
           element_id: 'wall-1')
  end

  before do
    login_as(user)
  end

  describe 'GET /api/v3/bim/element_links' do
    it 'returns all element links' do
      get '/api/v3/bim/element_links'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('Collection')
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].size).to eq(1)
    end

    it 'filters by work_package_id' do
      other_wp = create(:work_package, project: project)
      create(:bim_element_link, work_package: other_wp, ifc_model: ifc_model, element_id: 'wall-2')

      get "/api/v3/bim/element_links?work_package_id=#{work_package.id}"

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['_links']['work_package']['href']).to include(work_package.id.to_s)
    end

    it 'filters by ifc_model_id' do
      get "/api/v3/bim/element_links?ifc_model_id=#{ifc_model.id}"

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
    end

    it 'filters by relationship_type' do
      create(:bim_element_link, :responsible_for, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-2')

      get '/api/v3/bim/element_links?relationship_type=affected_by'

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['relationship_type']).to eq('affected_by')
    end

    it 'filters by status' do
      element_link.update(status: :completed)

      get '/api/v3/bim/element_links?status=completed'

      json = JSON.parse(response.body)
      expect(json['total']).to eq(1)
      expect(json['_embedded']['elements'].first['status']).to eq('completed')
    end

    it 'supports pagination' do
      10.times do |i|
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: "wall-#{i + 2}")
      end

      get '/api/v3/bim/element_links?page=1&per_page=5'

      json = JSON.parse(response.body)
      expect(json['count']).to eq(5)
      expect(json['_links']['next']).to be_present
    end
  end

  describe 'GET /api/v3/bim/element_links/:id' do
    it 'returns a single element link' do
      get "/api/v3/bim/element_links/#{element_link.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('ElementLink')
      expect(json['id']).to eq(element_link.id)
      expect(json['element_id']).to eq('wall-1')
      expect(json['relationship_type']).to eq('affected_by')
    end

    it 'returns 404 for non-existent link' do
      get '/api/v3/bim/element_links/99999'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v3/bim/element_links' do
    let(:valid_params) do
      {
        element_link: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_id: 'door-1',
          relationship_type: 'responsible_for'
        }
      }
    end

    it 'creates a new element link' do
      expect do
        post '/api/v3/bim/element_links', params: valid_params
      end.to change(Bim::ElementLink, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['element_id']).to eq('door-1')
      expect(json['relationship_type']).to eq('responsible_for')
    end

    it 'returns 422 for invalid params' do
      invalid_params = { element_link: { element_id: '' } }

      post '/api/v3/bim/element_links', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('Error')
    end
  end

  describe 'PATCH /api/v3/bim/element_links/:id' do
    it 'updates an element link' do
      patch "/api/v3/bim/element_links/#{element_link.id}",
            params: { element_link: { status: 'completed' } }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('completed')
      expect(element_link.reload.status).to eq('completed')
    end

    it 'updates relationship_type' do
      patch "/api/v3/bim/element_links/#{element_link.id}",
            params: { element_link: { relationship_type: 'observes' } }

      expect(response).to have_http_status(:ok)
      expect(element_link.reload.relationship_type).to eq('observes')
    end
  end

  describe 'DELETE /api/v3/bim/element_links/:id' do
    it 'deletes an element link' do
      expect do
        delete "/api/v3/bim/element_links/#{element_link.id}"
      end.to change(Bim::ElementLink, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent link' do
      delete '/api/v3/bim/element_links/99999'

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'without proper permissions' do
    let(:unauthorized_user) { create(:user) }

    before do
      login_as(unauthorized_user)
    end

    it 'returns 403 for index' do
      get '/api/v3/bim/element_links'

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for create' do
      post '/api/v3/bim/element_links', params: {
        element_link: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_id: 'door-1',
          relationship_type: 'responsible_for'
        }
      }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
