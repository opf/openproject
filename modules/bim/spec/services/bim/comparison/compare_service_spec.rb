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

RSpec.describe Bim::Comparison::CompareService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:model1) { create(:ifc_model, project: project, title: 'Version 1') }
  let(:model2) { create(:ifc_model, project: project, title: 'Version 2') }

  before do
    # Mock metadata for model1 (old version)
    allow(model1).to receive(:metadata).and_return({
                                                      'elements' => {
                                                        'wall-1' => {
                                                          'properties' => {
                                                            'type' => 'IfcWall',
                                                            'name' => 'Wall 1',
                                                            'height' => '3000'
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'wall1_v1',
                                                            'boundingBox' => {
                                                              'min' => [0, 0, 0],
                                                              'max' => [5000, 200, 3000]
                                                            }
                                                          }
                                                        },
                                                        'wall-2' => {
                                                          'properties' => {
                                                            'type' => 'IfcWall',
                                                            'name' => 'Wall 2'
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'wall2_v1'
                                                          }
                                                        },
                                                        'door-1' => {
                                                          'properties' => {
                                                            'type' => 'IfcDoor',
                                                            'name' => 'Door 1'
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'door1_v1'
                                                          }
                                                        }
                                                      }
                                                    })

    # Mock metadata for model2 (new version)
    allow(model2).to receive(:metadata).and_return({
                                                      'elements' => {
                                                        'wall-1' => {
                                                          'properties' => {
                                                            'type' => 'IfcWall',
                                                            'name' => 'Wall 1',
                                                            'height' => '3500' # Changed
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'wall1_v2', # Changed
                                                            'boundingBox' => {
                                                              'min' => [0, 0, 0],
                                                              'max' => [5000, 200, 3500]
                                                            }
                                                          }
                                                        },
                                                        'wall-2' => {
                                                          'properties' => {
                                                            'type' => 'IfcWall',
                                                            'name' => 'Wall 2'
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'wall2_v1' # Unchanged
                                                          }
                                                        },
                                                        'window-1' => { # New element
                                                          'properties' => {
                                                            'type' => 'IfcWindow',
                                                            'name' => 'Window 1'
                                                          },
                                                          'geometry' => {
                                                            'hash' => 'window1_v1'
                                                          }
                                                        }
                                                        # door-1 deleted
                                                      }
                                                    })
  end

  subject(:service) do
    described_class.new(
      model1: model1,
      model2: model2,
      options: { user: user }
    )
  end

  describe '#call' do
    it 'creates a comparison record' do
      expect { service.call }.to change(Bim::ModelComparison, :count).by(1)
    end

    it 'detects added elements' do
      result = service.call
      comparison = result.result

      expect(comparison.added_count).to eq(1)
      expect(comparison.added_elements.first[:element_id]).to eq('window-1')
    end

    it 'detects deleted elements' do
      result = service.call
      comparison = result.result

      expect(comparison.deleted_count).to eq(1)
      expect(comparison.deleted_elements.first[:element_id]).to eq('door-1')
    end

    it 'detects modified elements' do
      result = service.call
      comparison = result.result

      expect(comparison.modified_count).to eq(1)
      expect(comparison.modified_elements.first[:element_id]).to eq('wall-1')
    end

    it 'detects unchanged elements' do
      result = service.call
      comparison = result.result

      expect(comparison.unchanged_count).to eq(1)
      expect(comparison.unchanged_elements.first[:element_id]).to eq('wall-2')
    end

    it 'marks comparison as completed' do
      result = service.call
      comparison = result.result

      expect(comparison.status).to eq('completed')
      expect(comparison.completed_at).to be_present
      expect(comparison.comparison_time).to be_present
    end

    it 'stores comparison options' do
      service = described_class.new(
        model1: model1,
        model2: model2,
        options: {
          user: user,
          detect_geometry_changes: false
        }
      )

      result = service.call
      comparison = result.result

      expect(comparison.comparison_options[:detect_geometry_changes]).to be false
    end

    it 'calculates statistics' do
      result = service.call
      comparison = result.result

      expect(comparison.statistics['total_elements_model1']).to eq(3)
      expect(comparison.statistics['total_elements_model2']).to eq(3)
      expect(comparison.statistics['change_percentage']).to be_a(Float)
    end
  end

  describe 'geometry change detection' do
    it 'detects geometry changes' do
      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      geometry_change = modified[:changes].find { |c| c[:type] == 'geometry' }

      expect(geometry_change).to be_present
      expect(geometry_change[:description]).to eq('Geometry changed')
    end

    it 'analyzes bounding box changes' do
      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      geometry_change = modified[:changes].find { |c| c[:type] == 'geometry' }

      expect(geometry_change[:details][:size_changed]).to be true
      expect(geometry_change[:details][:size_delta][:depth]).to eq(500)
    end
  end

  describe 'property change detection' do
    it 'detects property changes' do
      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      property_change = modified[:changes].find { |c| c[:type] == 'property' }

      expect(property_change).to be_present
      expect(property_change[:property]).to eq('height')
      expect(property_change[:old_value]).to eq('3000')
      expect(property_change[:new_value]).to eq('3500')
    end

    it 'ignores specified properties' do
      service = described_class.new(
        model1: model1,
        model2: model2,
        options: { ignore_properties: ['height'] }
      )

      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      property_changes = modified[:changes].select { |c| c[:type] == 'property' }

      expect(property_changes.none? { |c| c[:property] == 'height' }).to be true
    end
  end

  describe 'validation' do
    it 'requires model1' do
      service = described_class.new(model1: nil, model2: model2)

      result = service.call

      expect(result).not_to be_success
      expect(result.errors).to include('model1 is required')
    end

    it 'requires model2' do
      service = described_class.new(model1: model1, model2: nil)

      result = service.call

      expect(result).not_to be_success
      expect(result.errors).to include('model2 is required')
    end

    it 'prevents comparing model with itself' do
      service = described_class.new(model1: model1, model2: model1)

      result = service.call

      expect(result).not_to be_success
      expect(result.errors).to include('Cannot compare model with itself')
    end

    it 'requires models in same project' do
      other_project = create(:project)
      other_model = create(:ifc_model, project: other_project)

      service = described_class.new(model1: model1, model2: other_model)

      result = service.call

      expect(result).not_to be_success
      expect(result.errors).to include('Models must be in same project')
    end
  end

  describe 'options' do
    it 'can disable geometry change detection' do
      service = described_class.new(
        model1: model1,
        model2: model2,
        options: { detect_geometry_changes: false }
      )

      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      geometry_changes = modified[:changes].select { |c| c[:type] == 'geometry' }

      expect(geometry_changes).to be_empty
    end

    it 'can disable property change detection' do
      service = described_class.new(
        model1: model1,
        model2: model2,
        options: { detect_property_changes: false }
      )

      result = service.call
      comparison = result.result

      modified = comparison.modified_elements.first
      property_changes = modified[:changes].select { |c| c[:type] == 'property' }

      expect(property_changes).to be_empty
    end
  end

  describe 'statistics calculation' do
    it 'counts changes by type' do
      result = service.call
      comparison = result.result

      stats = comparison.statistics
      expect(stats['geometry_changes']).to be >= 0
      expect(stats['property_changes']).to be >= 0
    end

    it 'groups changes by element type' do
      result = service.call
      comparison = result.result

      by_type = comparison.statistics['by_type']
      expect(by_type).to have_key('IfcWall')
      expect(by_type).to have_key('IfcDoor')
      expect(by_type).to have_key('IfcWindow')
    end
  end
end
