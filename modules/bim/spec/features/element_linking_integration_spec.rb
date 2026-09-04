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

RSpec.describe 'Element Linking Integration', type: :feature do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project: project, subject: 'Fix structural issues') }
  let(:ifc_model) { create(:ifc_model, :with_xkt_attachment, project: project, title: 'Building A') }

  before do
    login_as(user)

    # Mock IFC model metadata
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-101' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Exterior Wall 101'
                                                             },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'abc123'
                                                             }
                                                           },
                                                           'wall-102' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Interior Wall 102'
                                                             },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'def456'
                                                             }
                                                           },
                                                           'door-201' => {
                                                             'properties' => {
                                                               'type' => 'IfcDoor',
                                                               'name' => 'Main Entrance Door'
                                                             },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'ghi789'
                                                             }
                                                           }
                                                         }
                                                       })
  end

  describe 'Complete workflow: Manual element linking' do
    it 'creates links from work package to BIM elements' do
      # Step 1: Navigate to API and create a link
      post '/api/v3/bim/element_links', params: {
        element_link: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_id: 'wall-101',
          relationship_type: 'affected_by'
        }
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      link_id = json['id']

      # Step 2: Verify link was created
      expect(Bim::ElementLink.count).to eq(1)
      link = Bim::ElementLink.first
      expect(link.work_package).to eq(work_package)
      expect(link.ifc_model).to eq(ifc_model)
      expect(link.element_id).to eq('wall-101')
      expect(link.relationship_type).to eq('affected_by')
      expect(link.status).to eq('active')

      # Step 3: Retrieve the link
      get "/api/v3/bim/element_links/#{link_id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['element_id']).to eq('wall-101')
      expect(json['relationship_type']).to eq('affected_by')

      # Step 4: Update link status to completed
      patch "/api/v3/bim/element_links/#{link_id}", params: {
        element_link: { status: 'completed' }
      }

      expect(response).to have_http_status(:ok)
      expect(link.reload.status).to eq('completed')

      # Step 5: Delete the link
      delete "/api/v3/bim/element_links/#{link_id}"

      expect(response).to have_http_status(:no_content)
      expect(Bim::ElementLink.count).to eq(0)
    end
  end

  describe 'Complete workflow: Template-based linking' do
    let!(:template) do
      create(:bim_link_template,
             name: 'Structural Elements',
             project: project,
             author: user,
             relationship_type: :responsible_for,
             element_filters: {
               'types' => ['IfcWall']
             })
    end

    it 'creates links using template with dry-run and application' do
      # Step 1: Preview template application (dry-run)
      post '/api/v3/bim/element_links/apply_template', params: {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        template_id: template.id,
        dry_run: true
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['matching_elements']).to contain_exactly('wall-101', 'wall-102')
      expect(json['count']).to eq(2)
      expect(Bim::ElementLink.count).to eq(0) # No links created yet

      # Step 2: Apply template to create links
      post '/api/v3/bim/element_links/apply_template', params: {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        template_id: template.id,
        dry_run: false
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success_count']).to eq(2)
      expect(json['failure_count']).to eq(0)

      # Step 3: Verify links were created with template reference
      expect(Bim::ElementLink.count).to eq(2)
      links = Bim::ElementLink.all
      expect(links.map(&:element_id)).to contain_exactly('wall-101', 'wall-102')
      expect(links.first.template).to eq(template)
      expect(links.first.relationship_type).to eq('responsible_for')
    end
  end

  describe 'Complete workflow: Bulk operations' do
    it 'creates multiple links and performs bulk status update' do
      # Step 1: Bulk create links
      post '/api/v3/bim/element_links/bulk_create', params: {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-101', 'wall-102', 'door-201'],
        relationship_type: 'affected_by'
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success_count']).to eq(3)

      # Step 2: Get all link IDs
      link_ids = Bim::ElementLink.pluck(:id)
      expect(link_ids.size).to eq(3)

      # Step 3: Bulk status change to completed
      post '/api/v3/bim/element_links/bulk_status_change', params: {
        link_ids: link_ids,
        new_status: 'completed'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['updated_count']).to eq(3)

      # Step 4: Verify all links are completed
      expect(Bim::ElementLink.where(status: :completed).count).to eq(3)

      # Step 5: Bulk delete (soft)
      post '/api/v3/bim/element_links/bulk_delete', params: {
        link_ids: link_ids,
        soft_delete: true
      }

      expect(response).to have_http_status(:ok)
      expect(Bim::ElementLink.where(status: :archived).count).to eq(3)
    end
  end

  describe 'Complete workflow: Work package creation from elements' do
    let(:work_package_type) { create(:type, name: 'Task') }

    it 'creates work packages from element groups' do
      # Create work packages grouped by element type
      post '/api/v3/bim/element_links/create_work_packages', params: {
        ifc_model_id: ifc_model.id,
        element_ids: ['wall-101', 'wall-102', 'door-201'],
        work_package_template: {
          project_id: project.id,
          type_id: work_package_type.id,
          subject: 'Work on {group} ({count} elements)',
          description: 'Maintenance work'
        },
        relationship_type: 'responsible_for',
        grouping_strategy: 'by_type'
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      # Should create 2 work packages: one for walls, one for doors
      expect(json['work_package_count']).to eq(2)
      expect(json['link_count']).to eq(3)

      # Verify work packages were created with correct subjects
      wp_subjects = WorkPackage.where(project: project).pluck(:subject)
      expect(wp_subjects).to include(match(/IfcWall.*2 elements/))
      expect(wp_subjects).to include(match(/IfcDoor.*1 element/))

      # Verify links were created
      expect(Bim::ElementLink.count).to eq(3)
    end
  end

  describe 'Complete workflow: Element property refresh' do
    let!(:link) do
      create(:bim_element_link,
             work_package: work_package,
             ifc_model: ifc_model,
             element_id: 'wall-101',
             element_properties: {
               'type' => 'IfcWall',
               'geometry' => { 'hash' => 'old_hash' }
             })
    end

    it 'detects changed elements and refreshes properties' do
      # Step 1: Check initial state
      expect(link.geometry_changed?).to be true # hash is different

      # Step 2: Refresh properties
      post '/api/v3/bim/element_links/refresh_properties', params: {
        link_ids: [link.id]
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['refreshed_count']).to eq(1)
      expect(json['changed_count']).to eq(1)

      # Step 3: Verify properties were updated
      link.reload
      expect(link.element_properties['geometry']['hash']).to eq('abc123')
      expect(link.geometry_changed?).to be false
    end
  end

  describe 'Complete workflow: Template management' do
    it 'creates, clones, and uses templates' do
      # Step 1: Create a template
      post '/api/v3/bim/link_templates', params: {
        link_template: {
          name: 'Level 1 Walls',
          description: 'All walls on Level 1',
          relationship_type: 'affected_by',
          element_filters: {
            'types' => ['IfcWall'],
            'locations' => {
              'storey' => ['Level 1']
            }
          },
          project_id: project.id
        }
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      template_id = json['id']

      # Step 2: Get template statistics (should be 0 initially)
      get "/api/v3/bim/link_templates/#{template_id}/statistics"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['total_links']).to eq(0)

      # Step 3: Apply template
      post '/api/v3/bim/element_links/apply_template', params: {
        work_package_id: work_package.id,
        ifc_model_id: ifc_model.id,
        template_id: template_id
      }

      expect(response).to have_http_status(:created)

      # Step 4: Check statistics again
      get "/api/v3/bim/link_templates/#{template_id}/statistics"

      json = JSON.parse(response.body)
      expect(json['total_links']).to eq(2)
      expect(json['active_links']).to eq(2)

      # Step 5: Clone template with modifications
      post "/api/v3/bim/link_templates/#{template_id}/clone", params: {
        new_name: 'Level 1 Walls - Observes',
        modifications: {
          relationship_type: 'observes'
        }
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Level 1 Walls - Observes')
      expect(json['relationship_type']).to eq('observes')
      expect(json['element_filters']).to eq({
                                               'types' => ['IfcWall'],
                                               'locations' => {
                                                 'storey' => ['Level 1']
                                               }
                                             })
    end
  end

  describe 'Error handling' do
    it 'handles duplicate links gracefully' do
      # Create first link
      post '/api/v3/bim/element_links', params: {
        element_link: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_id: 'wall-101',
          relationship_type: 'affected_by'
        }
      }

      expect(response).to have_http_status(:created)

      # Try to create duplicate
      post '/api/v3/bim/element_links', params: {
        element_link: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_id: 'wall-101',
          relationship_type: 'responsible_for'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include('already been taken')
    end

    it 'handles rate limiting on bulk operations' do
      # Make 11 requests (limit is 10)
      11.times do
        post '/api/v3/bim/element_links/bulk_create', params: {
          work_package_id: work_package.id,
          ifc_model_id: ifc_model.id,
          element_ids: ["wall-#{rand(1000)}"],
          relationship_type: 'affected_by'
        }
      end

      # Last request should be rate limited
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
