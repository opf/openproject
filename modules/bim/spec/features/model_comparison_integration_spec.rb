# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'rails_helper'

RSpec.describe 'Model Comparison Integration', type: :feature do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:model_v1) { create(:ifc_model, project: project, title: 'Office Building V1') }
  let(:model_v2) { create(:ifc_model, project: project, title: 'Office Building V2') }

  before do
    login_as(user)

    # Mock metadata for V1
    allow(model_v1).to receive(:metadata).and_return({
                                                        'elements' => {
                                                          'wall-1' => {
                                                            'properties' => { 'type' => 'IfcWall', 'name' => 'Exterior Wall' },
                                                            'geometry' => { 'hash' => 'wall1_v1' }
                                                          },
                                                          'door-1' => {
                                                            'properties' => { 'type' => 'IfcDoor', 'name' => 'Main Entrance' },
                                                            'geometry' => { 'hash' => 'door1_v1' }
                                                          }
                                                        }
                                                      })

    # Mock metadata for V2 (changes made)
    allow(model_v2).to receive(:metadata).and_return({
                                                        'elements' => {
                                                          'wall-1' => {
                                                            'properties' => { 'type' => 'IfcWall', 'name' => 'Exterior Wall', 'height' => '3500' }, # Modified
                                                            'geometry' => { 'hash' => 'wall1_v2' } # Changed
                                                          },
                                                          'window-1' => { # Added
                                                            'properties' => { 'type' => 'IfcWindow', 'name' => 'Window 1' },
                                                            'geometry' => { 'hash' => 'window1_v1' }
                                                          }
                                                          # door-1 removed
                                                        }
                                                      })
  end

  describe 'Complete workflow: Version comparison and approval' do
    it 'compares two models, reviews changes, and approves' do
      # Step 1: Create comparison
      post '/api/v3/bim/comparisons', params: {
        model1_id: model_v1.id,
        model2_id: model_v2.id,
        name: 'V1 → V2 Comparison',
        description: 'Comparing initial design to updated version'
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      comparison_id = json['id']

      # Verify comparison completed
      expect(json['status']).to eq('completed')
      expect(json['added_count']).to eq(1) # window-1
      expect(json['deleted_count']).to eq(1) # door-1
      expect(json['modified_count']).to eq(1) # wall-1

      # Step 2: Review comparison details
      get "/api/v3/bim/comparisons/#{comparison_id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Verify changes are captured
      expect(json['changes_data']['added'].size).to eq(1)
      expect(json['changes_data']['added'].first['element_id']).to eq('window-1')

      expect(json['changes_data']['deleted'].size).to eq(1)
      expect(json['changes_data']['deleted'].first['element_id']).to eq('door-1')

      expect(json['changes_data']['modified'].size).to eq(1)
      expect(json['changes_data']['modified'].first['element_id']).to eq('wall-1')

      # Step 3: Approve comparison
      post "/api/v3/bim/comparisons/#{comparison_id}/approve", params: {
        comment: 'Changes approved - proceed with updated design'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('approved')
      expect(json['status_comment']).to eq('Changes approved - proceed with updated design')
    end
  end

  describe 'Complete workflow: Geometry change detection' do
    before do
      allow(model_v1).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'column-1' => {
                                                              'properties' => { 'type' => 'IfcColumn' },
                                                              'geometry' => {
                                                                'hash' => 'col_v1',
                                                                'boundingBox' => {
                                                                  'min' => [0, 0, 0],
                                                                  'max' => [500, 500, 3000]
                                                                }
                                                              }
                                                            }
                                                          }
                                                        })

      allow(model_v2).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'column-1' => {
                                                              'properties' => { 'type' => 'IfcColumn' },
                                                              'geometry' => {
                                                                'hash' => 'col_v2', # Changed
                                                                'boundingBox' => {
                                                                  'min' => [100, 0, 0], # Moved
                                                                  'max' => [600, 500, 3000]
                                                                }
                                                              }
                                                            }
                                                          }
                                                        })
    end

    it 'detects geometry changes with position delta' do
      service = Bim::Comparison::CompareService.new(
        model1: model_v1,
        model2: model_v2,
        options: { user: user }
      )

      result = service.call
      comparison = result.result

      expect(comparison.modified_count).to eq(1)

      modified = comparison.modified_elements.first
      geometry_change = modified[:changes].find { |c| c[:type] == 'geometry' }

      expect(geometry_change).to be_present
      expect(geometry_change[:details][:position_changed]).to be true
      expect(geometry_change[:details][:position_delta][:x]).to eq(100)
    end
  end

  describe 'Complete workflow: Property change filtering' do
    before do
      allow(model_v1).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'wall-1' => {
                                                              'properties' => {
                                                                'type' => 'IfcWall',
                                                                'height' => '3000',
                                                                'FireRating' => '60min',
                                                                'LoadBearing' => 'true'
                                                              },
                                                              'geometry' => { 'hash' => 'wall_v1' }
                                                            }
                                                          }
                                                        })

      allow(model_v2).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'wall-1' => {
                                                              'properties' => {
                                                                'type' => 'IfcWall',
                                                                'height' => '3500', # Changed
                                                                'FireRating' => '90min', # Changed
                                                                'LoadBearing' => 'true'
                                                              },
                                                              'geometry' => { 'hash' => 'wall_v1' } # Unchanged
                                                            }
                                                          }
                                                        })
    end

    it 'detects all property changes' do
      service = Bim::Comparison::CompareService.new(
        model1: model_v1,
        model2: model_v2,
        options: { user: user }
      )

      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      property_changes = modified[:changes].select { |c| c[:type] == 'property' }

      expect(property_changes.size).to eq(2)
      expect(property_changes.any? { |c| c[:property] == 'height' }).to be true
      expect(property_changes.any? { |c| c[:property] == 'FireRating' }).to be true
    end

    it 'can ignore specific properties' do
      service = Bim::Comparison::CompareService.new(
        model1: model_v1,
        model2: model_v2,
        options: { user: user, ignore_properties: ['height'] }
      )

      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      property_changes = modified[:changes].select { |c| c[:type] == 'property' }

      expect(property_changes.size).to eq(1)
      expect(property_changes.first[:property]).to eq('FireRating')
    end
  end

  describe 'Complete workflow: Multiple comparisons and trending' do
    let!(:model_v3) { create(:ifc_model, project: project, title: 'Office Building V3') }

    before do
      allow(model_v3).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'wall-1' => {
                                                              'properties' => { 'type' => 'IfcWall' },
                                                              'geometry' => { 'hash' => 'wall_v3' }
                                                            }
                                                          }
                                                        })
    end

    it 'creates multiple comparisons and tracks evolution' do
      # V1 → V2
      post '/api/v3/bim/comparisons', params: {
        model1_id: model_v1.id,
        model2_id: model_v2.id,
        name: 'V1 → V2'
      }
      comp1_id = JSON.parse(response.body)['id']

      # V2 → V3
      post '/api/v3/bim/comparisons', params: {
        model1_id: model_v2.id,
        model2_id: model_v3.id,
        name: 'V2 → V3'
      }
      comp2_id = JSON.parse(response.body)['id']

      # List comparisons for model
      get '/api/v3/bim/comparisons', params: { model_id: model_v2.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comparisons'].size).to eq(2)
    end
  end

  describe 'Error handling' do
    it 'prevents comparing model with itself' do
      post '/api/v3/bim/comparisons', params: {
        model1_id: model_v1.id,
        model2_id: model_v1.id
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'requires both models in same project' do
      other_project = create(:project)
      other_model = create(:ifc_model, project: other_project)

      post '/api/v3/bim/comparisons', params: {
        model1_id: model_v1.id,
        model2_id: other_model.id
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
