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

RSpec.describe Bim::BulkLinkOperationsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(current_user: user) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project: project) }
  let(:ifc_model) { create(:ifc_model, :with_xkt_attachment, project: project) }

  before do
    # Mock IFC model metadata
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-1' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Wall 001'
                                                             },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'abc123'
                                                             }
                                                           },
                                                           'wall-2' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Wall 002'
                                                             },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 2'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'def456'
                                                             }
                                                           },
                                                           'door-1' => {
                                                             'properties' => {
                                                               'type' => 'IfcDoor',
                                                               'name' => 'Door 001'
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

  describe '#create_bulk_links' do
    let(:element_ids) { ['wall-1', 'wall-2'] }
    let(:relationship_type) { :affected_by }

    it 'creates links for all provided element IDs' do
      expect do
        service.create_bulk_links(
          work_package: work_package,
          ifc_model: ifc_model,
          element_ids: element_ids,
          relationship_type: relationship_type
        )
      end.to change(Bim::ElementLink, :count).by(2)
    end

    it 'returns success result with created links' do
      result = service.create_bulk_links(
        work_package: work_package,
        ifc_model: ifc_model,
        element_ids: element_ids,
        relationship_type: relationship_type
      )

      expect(result).to be_success
      expect(result[:created].size).to eq(2)
      expect(result[:success_count]).to eq(2)
      expect(result[:failure_count]).to eq(0)
    end

    it 'sets relationship type correctly' do
      result = service.create_bulk_links(
        work_package: work_package,
        ifc_model: ifc_model,
        element_ids: element_ids,
        relationship_type: :responsible_for
      )

      expect(result[:created].first.relationship_type).to eq('responsible_for')
    end

    it 'captures element properties' do
      result = service.create_bulk_links(
        work_package: work_package,
        ifc_model: ifc_model,
        element_ids: ['wall-1'],
        relationship_type: relationship_type
      )

      link = result[:created].first
      expect(link.element_properties['type']).to eq('IfcWall')
      expect(link.element_properties['name']).to eq('Wall 001')
    end

    context 'when some elements fail validation' do
      before do
        # Create existing link to cause uniqueness validation failure
        create(:bim_element_link,
               work_package: work_package,
               ifc_model: ifc_model,
               element_id: 'wall-1')
      end

      it 'creates successful links and reports failures' do
        result = service.create_bulk_links(
          work_package: work_package,
          ifc_model: ifc_model,
          element_ids: element_ids,
          relationship_type: relationship_type
        )

        expect(result).to be_success
        expect(result[:success_count]).to eq(1)
        expect(result[:failure_count]).to eq(1)
        expect(result[:failed].first[:element_id]).to eq('wall-1')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when element_ids is empty' do
        result = service.create_bulk_links(
          work_package: work_package,
          ifc_model: ifc_model,
          element_ids: [],
          relationship_type: relationship_type
        )

        expect(result).not_to be_success
        expect(result.message).to include('No element IDs provided')
      end

      it 'returns error when relationship_type is invalid' do
        result = service.create_bulk_links(
          work_package: work_package,
          ifc_model: ifc_model,
          element_ids: element_ids,
          relationship_type: :invalid_type
        )

        expect(result).not_to be_success
        expect(result.message).to include('Invalid relationship type')
      end
    end

    context 'with template' do
      let(:template) { create(:bim_link_template) }

      it 'associates links with template' do
        result = service.create_bulk_links(
          work_package: work_package,
          ifc_model: ifc_model,
          element_ids: element_ids,
          relationship_type: relationship_type,
          template: template
        )

        expect(result[:created].first.template).to eq(template)
      end
    end
  end

  describe '#apply_template' do
    let(:template) do
      create(:bim_link_template,
             relationship_type: :affected_by,
             element_filters: { 'types' => ['IfcWall'] })
    end

    it 'creates links for all matching elements' do
      expect do
        service.apply_template(
          work_package: work_package,
          ifc_model: ifc_model,
          template: template
        )
      end.to change(Bim::ElementLink, :count).by(2)
    end

    it 'uses template relationship type' do
      result = service.apply_template(
        work_package: work_package,
        ifc_model: ifc_model,
        template: template
      )

      expect(result[:created].first.relationship_type).to eq('affected_by')
    end

    it 'associates links with template' do
      result = service.apply_template(
        work_package: work_package,
        ifc_model: ifc_model,
        template: template
      )

      expect(result[:created].first.template).to eq(template)
    end

    context 'with dry_run' do
      it 'returns matching elements without creating links' do
        expect do
          result = service.apply_template(
            work_package: work_package,
            ifc_model: ifc_model,
            template: template,
            dry_run: true
          )

          expect(result[:matching_elements]).to contain_exactly('wall-1', 'wall-2')
        end.not_to change(Bim::ElementLink, :count)
      end
    end
  end

  describe '#update_bulk_links' do
    let!(:links) do
      [
        create(:bim_element_link, work_package: work_package, status: :active),
        create(:bim_element_link, work_package: work_package, status: :active)
      ]
    end
    let(:link_ids) { links.map(&:id) }

    it 'updates all specified links' do
      result = service.update_bulk_links(
        link_ids: link_ids,
        attributes: { status: :completed }
      )

      expect(result).to be_success
      expect(result[:success_count]).to eq(2)
      expect(links.first.reload.status).to eq('completed')
      expect(links.second.reload.status).to eq('completed')
    end

    it 'returns error when no link_ids provided' do
      result = service.update_bulk_links(
        link_ids: [],
        attributes: { status: :completed }
      )

      expect(result).not_to be_success
    end

    it 'returns error when no attributes provided' do
      result = service.update_bulk_links(
        link_ids: link_ids,
        attributes: {}
      )

      expect(result).not_to be_success
    end
  end

  describe '#delete_bulk_links' do
    let!(:links) do
      [
        create(:bim_element_link, work_package: work_package),
        create(:bim_element_link, work_package: work_package)
      ]
    end
    let(:link_ids) { links.map(&:id) }

    context 'with soft delete' do
      it 'archives links instead of deleting' do
        result = service.delete_bulk_links(
          link_ids: link_ids,
          soft_delete: true
        )

        expect(result).to be_success
        expect(result[:archived_count]).to eq(2)
        expect(links.first.reload.status).to eq('archived')
      end
    end

    context 'with hard delete' do
      it 'permanently deletes links' do
        expect do
          service.delete_bulk_links(
            link_ids: link_ids,
            soft_delete: false
          )
        end.to change(Bim::ElementLink, :count).by(-2)
      end
    end

    it 'returns error when no link_ids provided' do
      result = service.delete_bulk_links(link_ids: [])
      expect(result).not_to be_success
    end
  end

  describe '#create_work_packages_from_elements' do
    let(:element_ids) { ['wall-1', 'wall-2', 'door-1'] }
    let(:work_package_template) do
      {
        project_id: project.id,
        type_id: create(:type).id,
        subject: 'Work on {group} ({count} elements)',
        description: 'Generated from BIM elements'
      }
    end

    context 'with individual grouping' do
      it 'creates one work package per element' do
        expect do
          service.create_work_packages_from_elements(
            ifc_model: ifc_model,
            element_ids: element_ids,
            work_package_template: work_package_template,
            relationship_type: :responsible_for,
            grouping_strategy: :individual
          )
        end.to change(WorkPackage, :count).by(3)
      end
    end

    context 'with by_type grouping' do
      it 'groups elements by type' do
        result = service.create_work_packages_from_elements(
          ifc_model: ifc_model,
          element_ids: element_ids,
          work_package_template: work_package_template,
          relationship_type: :responsible_for,
          grouping_strategy: :by_type
        )

        expect(result[:work_package_count]).to eq(2) # IfcWall and IfcDoor
        expect(result[:link_count]).to eq(3)
      end
    end

    context 'with by_location grouping' do
      it 'groups elements by storey' do
        result = service.create_work_packages_from_elements(
          ifc_model: ifc_model,
          element_ids: element_ids,
          work_package_template: work_package_template,
          relationship_type: :responsible_for,
          grouping_strategy: :by_location
        )

        expect(result[:work_package_count]).to eq(2) # Level 1 and Level 2
      end
    end

    context 'with all_in_one grouping' do
      it 'creates single work package for all elements' do
        result = service.create_work_packages_from_elements(
          ifc_model: ifc_model,
          element_ids: element_ids,
          work_package_template: work_package_template,
          relationship_type: :responsible_for,
          grouping_strategy: :all_in_one
        )

        expect(result[:work_package_count]).to eq(1)
        expect(result[:link_count]).to eq(3)
      end
    end

    it 'replaces placeholders in subject' do
      result = service.create_work_packages_from_elements(
        ifc_model: ifc_model,
        element_ids: ['wall-1', 'wall-2'],
        work_package_template: work_package_template,
        relationship_type: :responsible_for,
        grouping_strategy: :by_type
      )

      wp = result[:work_packages].first
      expect(wp.subject).to include('IfcWall')
      expect(wp.subject).to include('2 elements')
    end

    it 'returns error when no element_ids provided' do
      result = service.create_work_packages_from_elements(
        ifc_model: ifc_model,
        element_ids: [],
        work_package_template: work_package_template,
        relationship_type: :responsible_for
      )

      expect(result).not_to be_success
    end
  end

  describe '#refresh_element_properties' do
    let!(:link) do
      create(:bim_element_link,
             work_package: work_package,
             ifc_model: ifc_model,
             element_id: 'wall-1',
             element_properties: {
               'geometry' => { 'hash' => 'old_hash' },
               'type' => 'IfcWall'
             })
    end

    it 'refreshes properties from current metadata' do
      result = service.refresh_element_properties(link_ids: [link.id])

      expect(result).to be_success
      expect(result[:refreshed_count]).to eq(1)
      link.reload
      expect(link.element_properties['geometry']['hash']).to eq('abc123')
    end

    it 'identifies changed elements' do
      result = service.refresh_element_properties(link_ids: [link.id])

      expect(result[:changed_count]).to eq(1)
      expect(result[:changed].first.id).to eq(link.id)
    end

    it 'returns error when no link_ids provided' do
      result = service.refresh_element_properties(link_ids: [])
      expect(result).not_to be_success
    end
  end

  describe '#find_matching_elements' do
    let(:filters) do
      {
        'types' => ['IfcWall'],
        'locations' => { 'storey' => ['Level 1'] }
      }
    end

    it 'finds elements matching filters across models' do
      result = service.find_matching_elements(
        ifc_models: [ifc_model],
        filters: filters
      )

      expect(result).to be_success
      expect(result[:total_count]).to eq(1)
      expect(result[:results][ifc_model.id][:element_ids]).to contain_exactly('wall-1')
    end

    it 'works with multiple models' do
      another_model = create(:ifc_model, :with_xkt_attachment, project: project)
      allow(another_model).to receive(:metadata).and_return({
                                                               'elements' => {
                                                                 'wall-3' => {
                                                                   'properties' => { 'type' => 'IfcWall' },
                                                                   'spatial_structure' => { 'storey' => 'Level 1' }
                                                                 }
                                                               }
                                                             })

      result = service.find_matching_elements(
        ifc_models: [ifc_model, another_model],
        filters: filters
      )

      expect(result[:total_count]).to eq(2)
      expect(result[:model_count]).to eq(2)
    end

    it 'returns error when no ifc_models provided' do
      result = service.find_matching_elements(
        ifc_models: [],
        filters: filters
      )

      expect(result).not_to be_success
    end
  end

  describe '#bulk_status_change' do
    let!(:links) do
      [
        create(:bim_element_link, status: :active),
        create(:bim_element_link, status: :active)
      ]
    end
    let(:link_ids) { links.map(&:id) }

    it 'changes status for all links' do
      result = service.bulk_status_change(
        link_ids: link_ids,
        new_status: :completed
      )

      expect(result).to be_success
      expect(result[:updated_count]).to eq(2)
      expect(links.first.reload.status).to eq('completed')
      expect(links.second.reload.status).to eq('completed')
    end

    it 'returns error with invalid status' do
      result = service.bulk_status_change(
        link_ids: link_ids,
        new_status: :invalid_status
      )

      expect(result).not_to be_success
    end

    it 'returns error when no link_ids provided' do
      result = service.bulk_status_change(
        link_ids: [],
        new_status: :completed
      )

      expect(result).not_to be_success
    end
  end
end
