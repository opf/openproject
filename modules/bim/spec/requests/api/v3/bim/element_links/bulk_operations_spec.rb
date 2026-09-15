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

RSpec.describe 'API v3 BIM Element Links Bulk Operations', type: :request do
  let(:user) { create(:user, global_permissions: [:manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project: project) }
  let(:ifc_model) { create(:ifc_model, :with_xkt_attachment, project: project) }

  before do
    login_as(user)

    # Mock IFC metadata
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-1' => { 'properties' => { 'type' => 'IfcWall' } },
                                                           'wall-2' => { 'properties' => { 'type' => 'IfcWall' } },
                                                           'door-1' => { 'properties' => { 'type' => 'IfcDoor' } }
                                                         }
                                                       })
  end

  describe 'POST /api/v3/bim/element_links/bulk_create' do
    let(:valid_params) do
      {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-1', 'wall-2'],
        relationship_type: 'affected_by'
      }
    end

    it 'creates multiple links at once' do
      expect do
        post '/api/v3/bim/element_links/bulk_create', params: valid_params
      end.to change(Bim::ElementLink, :count).by(2)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['_type']).to eq('BulkOperationResult')
      expect(json['success_count']).to eq(2)
      expect(json['failure_count']).to eq(0)
      expect(json['created'].size).to eq(2)
    end

    it 'returns partial success when some links fail' do
      # Create existing link to cause uniqueness failure
      create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-1')

      post '/api/v3/bim/element_links/bulk_create', params: valid_params

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success_count']).to eq(1)
      expect(json['failure_count']).to eq(1)
      expect(json['failed'].size).to eq(1)
    end

    it 'returns error for invalid relationship_type' do
      invalid_params = valid_params.merge(relationship_type: 'invalid_type')

      post '/api/v3/bim/element_links/bulk_create', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v3/bim/element_links/bulk_update' do
    let!(:links) do
      [
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-1', status: :active),
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-2', status: :active)
      ]
    end

    it 'updates multiple links at once' do
      patch '/api/v3/bim/element_links/bulk_update', params: {
        link_ids: links.map(&:id),
        attributes: { status: 'completed' }
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success_count']).to eq(2)
      expect(links.first.reload.status).to eq('completed')
      expect(links.second.reload.status).to eq('completed')
    end

    it 'returns error when no link_ids provided' do
      patch '/api/v3/bim/element_links/bulk_update', params: {
        link_ids: [],
        attributes: { status: 'completed' }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v3/bim/element_links/bulk_delete' do
    let!(:links) do
      [
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-1'),
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-2')
      ]
    end

    context 'with soft delete' do
      it 'archives links instead of deleting' do
        expect do
          post '/api/v3/bim/element_links/bulk_delete', params: {
            link_ids: links.map(&:id),
            soft_delete: true
          }
        end.not_to change(Bim::ElementLink, :count)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['archived_count']).to eq(2)
        expect(links.first.reload.status).to eq('archived')
      end
    end

    context 'with hard delete' do
      it 'permanently deletes links' do
        expect do
          post '/api/v3/bim/element_links/bulk_delete', params: {
            link_ids: links.map(&:id),
            soft_delete: false
          }
        end.to change(Bim::ElementLink, :count).by(-2)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /api/v3/bim/element_links/bulk_status_change' do
    let!(:links) do
      [
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-1', status: :active),
        create(:bim_element_link, work_package: work_package, ifc_model: ifc_model, element_id: 'wall-2', status: :active)
      ]
    end

    it 'changes status for all links' do
      post '/api/v3/bim/element_links/bulk_status_change', params: {
        link_ids: links.map(&:id),
        new_status: 'completed'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['updated_count']).to eq(2)
      expect(links.first.reload.status).to eq('completed')
    end

    it 'returns error for invalid status' do
      post '/api/v3/bim/element_links/bulk_status_change', params: {
        link_ids: links.map(&:id),
        new_status: 'invalid_status'
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v3/bim/element_links/apply_template' do
    let(:template) do
      create(:bim_link_template,
             relationship_type: :affected_by,
             element_filters: { 'types' => ['IfcWall'] })
    end

    it 'creates links for matching elements' do
      expect do
        post '/api/v3/bim/element_links/apply_template', params: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          template_id: template.id
        }
      end.to change(Bim::ElementLink, :count).by(2)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success_count']).to eq(2)
    end

    context 'with dry_run' do
      it 'returns matching elements without creating links' do
        expect do
          post '/api/v3/bim/element_links/apply_template', params: {
            work_package_id: work_package.id,
            ifc_model_id: ifc_model.id,
            template_id: template.id,
            dry_run: true
          }
        end.not_to change(Bim::ElementLink, :count)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['matching_elements']).to contain_exactly('wall-1', 'wall-2')
        expect(json['count']).to eq(2)
      end
    end
  end

  describe 'POST /api/v3/bim/element_links/create_work_packages' do
    let(:work_package_type) { create(:type) }
    let(:valid_params) do
      {
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-1', 'wall-2'],
        work_package_template: {
          project_id: project.id,
          type_id: work_package_type.id,
          subject: 'Work on {group} ({count} elements)',
          description: 'Generated from BIM elements'
        },
        relationship_type: 'responsible_for',
        grouping_strategy: 'all_in_one'
      }
    end

    it 'creates work packages from elements' do
      expect do
        post '/api/v3/bim/element_links/create_work_packages', params: valid_params
      end.to change(WorkPackage, :count).by(1)
        .and change(Bim::ElementLink, :count).by(2)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['work_package_count']).to eq(1)
      expect(json['link_count']).to eq(2)
      expect(json['work_packages'].first['subject']).to include('2 elements')
    end

    it 'groups by type' do
      params = valid_params.merge(
        element_ids: ['wall-1', 'wall-2', 'door-1'],
        grouping_strategy: 'by_type'
      )

      expect do
        post '/api/v3/bim/element_links/create_work_packages', params: params
      end.to change(WorkPackage, :count).by(2) # IfcWall and IfcDoor groups

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['work_package_count']).to eq(2)
      expect(json['link_count']).to eq(3)
    end
  end

  describe 'POST /api/v3/bim/element_links/refresh_properties' do
    let!(:links) do
      [
        create(:bim_element_link,
               work_package: work_package,
               ifc_model: ifc_model,
               element_id: 'wall-1',
               element_properties: { 'type' => 'IfcWall', 'old_property' => 'old_value' })
      ]
    end

    it 'refreshes element properties' do
      post '/api/v3/bim/element_links/refresh_properties', params: {
        link_ids: links.map(&:id)
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['refreshed_count']).to eq(1)
    end
  end

  describe 'POST /api/v3/bim/element_links/find_matching' do
    let(:filters) do
      {
        'types' => ['IfcWall']
      }
    end

    it 'finds elements matching filters' do
      post '/api/v3/bim/element_links/find_matching', params: {
        ifc_model_ids: [ifc_model.id],
        filters: filters
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['total_count']).to eq(2)
      expect(json['model_count']).to eq(1)
      expect(json['results'][ifc_model.id.to_s]['element_ids']).to contain_exactly('wall-1', 'wall-2')
    end

    it 'works across multiple models' do
      another_model = create(:ifc_model, :with_xkt_attachment, project: project)
      allow(another_model).to receive(:metadata).and_return({
                                                               'elements' => {
                                                                 'wall-3' => { 'properties' => { 'type' => 'IfcWall' } }
                                                               }
                                                             })

      post '/api/v3/bim/element_links/find_matching', params: {
        ifc_model_ids: [ifc_model.id, another_model.id],
        filters: filters
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['total_count']).to eq(3)
      expect(json['model_count']).to eq(2)
    end
  end

  context 'rate limiting' do
    it 'enforces rate limits on bulk operations' do
      valid_params = {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-1'],
        relationship_type: 'affected_by'
      }

      # Make 10 requests (the limit)
      10.times do
        post '/api/v3/bim/element_links/bulk_create', params: valid_params
      end

      # 11th request should be rate limited
      post '/api/v3/bim/element_links/bulk_create', params: valid_params

      expect(response).to have_http_status(:too_many_requests)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Rate limit exceeded')
    end
  end

  context 'without proper permissions' do
    let(:unauthorized_user) { create(:user) }

    before do
      login_as(unauthorized_user)
    end

    it 'returns 403 for bulk_create' do
      post '/api/v3/bim/element_links/bulk_create', params: {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-1'],
        relationship_type: 'affected_by'
      }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
