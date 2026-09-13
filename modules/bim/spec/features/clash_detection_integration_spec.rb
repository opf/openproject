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

RSpec.describe 'Clash Detection Integration', type: :feature do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:ifc_model) { create(:ifc_model, :with_xkt_attachment, project: project, title: 'Office Building') }
  let(:work_package_type) { create(:type, name: 'Task') }

  before do
    login_as(user)

    # Mock IFC model metadata with realistic bounding boxes
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-101' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Exterior Wall North'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'abc123',
                                                               'boundingBox' => {
                                                                 'min' => [0.0, 0.0, 0.0],
                                                                 'max' => [10000.0, 300.0, 3500.0]
                                                               }
                                                             }
                                                           },
                                                           'wall-102' => {
                                                             'properties' => {
                                                               'type' => 'IfcWall',
                                                               'name' => 'Interior Wall Corridor'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'def456',
                                                               'boundingBox' => {
                                                                 'min' => [9950.0, 0.0, 0.0],
                                                                 'max' => [15000.0, 200.0, 3500.0]
                                                               }
                                                             }
                                                           },
                                                           'duct-201' => {
                                                             'properties' => {
                                                               'type' => 'IfcFlowSegment',
                                                               'name' => 'HVAC Duct Main'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'ghi789',
                                                               'boundingBox' => {
                                                                 'min' => [5000.0, -50.0, 2800.0],
                                                                 'max' => [10000.0, 450.0, 3100.0]
                                                               }
                                                             }
                                                           },
                                                           'column-301' => {
                                                             'properties' => {
                                                               'type' => 'IfcColumn',
                                                               'name' => 'Structural Column C1'
                                                             },
                                                             'geometry' => {
                                                               'hash' => 'jkl012',
                                                               'boundingBox' => {
                                                                 'min' => [7500.0, 7500.0, 0.0],
                                                                 'max' => [8000.0, 8000.0, 3500.0]
                                                               }
                                                             }
                                                           }
                                                         }
                                                       })
  end

  describe 'Complete workflow: Clash detection and resolution' do
    it 'detects clashes, approves, and resolves them' do
      # Step 1: Run clash detection
      post '/api/v3/bim/clashes/detect', params: {
        ifc_model_id: ifc_model.id,
        clearance_distance: 50.0,
        soft_clash_distance: 100.0,
        detect_hard_clashes: true,
        detect_soft_clashes: true
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['count']).to be > 0
      detection_run_id = json['detection_run_id']
      expect(detection_run_id).to be_present

      # Step 2: Get detected clashes
      get '/api/v3/bim/clashes', params: { ifc_model_id: ifc_model.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      clashes = json['clashes']
      expect(clashes).not_to be_empty

      clash = clashes.first
      clash_id = clash['id']

      # Step 3: Approve one clash as acceptable
      post "/api/v3/bim/clashes/#{clash_id}/approve", params: {
        comment: 'Minor overlap, acceptable per design standards'
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('approved')

      # Step 4: Resolve another clash
      if clashes.size > 1
        clash_to_resolve = clashes[1]
        post "/api/v3/bim/clashes/#{clash_to_resolve['id']}/resolve", params: {
          resolution_type: 'redesign',
          comment: 'Elements redesigned to eliminate overlap'
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('resolved')
        expect(json['resolution_type']).to eq('redesign')
      end

      # Step 5: Verify statistics reflect changes
      get '/api/v3/bim/clashes/statistics', params: { ifc_model_id: ifc_model.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['by_status']['approved']).to be >= 1
      if clashes.size > 1
        expect(json['by_status']['resolved']).to be >= 1
      end
    end
  end

  describe 'Complete workflow: Batch detection across multiple models' do
    let!(:ifc_model2) { create(:ifc_model, project: project, title: 'Building B', is_default: true) }

    before do
      allow(ifc_model2).to receive(:metadata).and_return({
                                                            'elements' => {
                                                              'beam-1' => {
                                                                'properties' => { 'type' => 'IfcBeam', 'name' => 'Beam 1' },
                                                                'geometry' => {
                                                                  'boundingBox' => {
                                                                    'min' => [0, 0, 3000],
                                                                    'max' => [5000, 300, 3500]
                                                                  }
                                                                }
                                                              },
                                                              'pipe-1' => {
                                                                'properties' => { 'type' => 'IfcPipe', 'name' => 'Pipe 1' },
                                                                'geometry' => {
                                                                  'boundingBox' => {
                                                                    'min' => [2000, 0, 3200],
                                                                    'max' => [3000, 200, 3400]
                                                                  }
                                                                }
                                                              }
                                                            }
                                                          })
    end

    it 'detects clashes across all models in project using batch service' do
      service = Bim::BatchClashDetectionService.new
      result = service.detect_across_models(
        project: project,
        options: {
          detect_hard_clashes: true,
          clearance_distance: 50.0
        }
      )

      expect(result).to be_success
      expect(result.result[:models_processed]).to eq(2)
      expect(result.result[:total_clashes]).to be >= 0
      expect(result.result[:detection_run_id]).to be_present

      # Verify both models have clashes recorded
      model1_clashes = Bim::Clash.where(ifc_model: ifc_model).count
      model2_clashes = Bim::Clash.where(ifc_model: ifc_model2).count

      expect(model1_clashes + model2_clashes).to eq(result.result[:total_clashes])
    end
  end

  describe 'Complete workflow: Detection run comparison' do
    let!(:run1_id) { 'run_20250101_001' }
    let!(:run2_id) { 'run_20250108_001' }

    before do
      # Create clashes from first run
      create(:bim_clash, ifc_model: ifc_model,
                         element_a_id: 'wall-101',
                         element_b_id: 'wall-102',
                         detection_run_id: run1_id,
                         severity: :critical)
      create(:bim_clash, ifc_model: ifc_model,
                         element_a_id: 'duct-201',
                         element_b_id: 'wall-101',
                         detection_run_id: run1_id,
                         severity: :major)

      # Create clashes from second run (one resolved, one new)
      create(:bim_clash, ifc_model: ifc_model,
                         element_a_id: 'wall-101',
                         element_b_id: 'wall-102',
                         detection_run_id: run2_id,
                         severity: :critical)
      create(:bim_clash, ifc_model: ifc_model,
                         element_a_id: 'column-301',
                         element_b_id: 'duct-201',
                         detection_run_id: run2_id,
                         severity: :minor)
    end

    it 'compares detection runs and identifies changes' do
      service = Bim::BatchClashDetectionService.new
      result = service.compare_detection_runs(
        ifc_model: ifc_model,
        run1_id: run1_id,
        run2_id: run2_id
      )

      expect(result).to be_success
      comparison = result.result

      expect(comparison[:run1_total]).to eq(2)
      expect(comparison[:run2_total]).to eq(2)
      expect(comparison[:persistent_count]).to eq(1) # wall-101 vs wall-102
      expect(comparison[:new_count]).to eq(1) # column-301 vs duct-201
      expect(comparison[:resolved_count]).to eq(1) # duct-201 vs wall-101

      expect(comparison[:improvement_rate]).to be_a(Float)
    end
  end

  describe 'Complete workflow: Clash grouping and analysis' do
    before do
      # Create clashes with wall-101 involved in multiple clashes (problematic element)
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'wall-101',
                         element_b_id: 'wall-102')
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'duct-201',
                         element_b_id: 'wall-101')
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'column-301',
                         element_b_id: 'wall-101')

      # Create spatial cluster
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'wall-102',
                         element_b_id: 'duct-201',
                         clash_point: { x: 10000.0, y: 200.0, z: 3000.0 })
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'column-301',
                         element_b_id: 'duct-201',
                         clash_point: { x: 10050.0, y: 220.0, z: 2950.0 })
    end

    it 'groups clashes by element involvement' do
      service = Bim::ClashGroupingService.new(ifc_model: ifc_model)
      result = service.group_by_element(min_clash_count: 2)

      expect(result).to be_success
      groups = result.result[:groups]

      # wall-101 should be identified as problematic (3 clashes)
      wall_group = groups.find { |g| g[:element_id] == 'wall-101' }
      expect(wall_group).to be_present
      expect(wall_group[:clash_count]).to eq(3)
      expect(wall_group[:element_name]).to eq('Exterior Wall North')
    end

    it 'groups clashes by spatial proximity' do
      service = Bim::ClashGroupingService.new(ifc_model: ifc_model)
      result = service.group_by_spatial_proximity(distance_threshold: 200.0)

      expect(result).to be_success
      clusters = result.result[:clusters]

      # Should identify cluster of closely spaced clashes
      expect(clusters).not_to be_empty
      cluster = clusters.first
      expect(cluster).to have_key(:centroid)
      expect(cluster).to have_key(:bounding_box)
      expect(cluster).to have_key(:clash_count)
    end

    it 'groups clashes by type pattern' do
      service = Bim::ClashGroupingService.new(ifc_model: ifc_model)
      result = service.group_by_type_pattern

      expect(result).to be_success
      groups = result.result[:groups]

      expect(groups).not_to be_empty
      # Should identify common patterns like "IfcWall vs IfcFlowSegment"
      expect(groups.first).to have_key(:type_pair)
      expect(groups.first).to have_key(:clash_count)
    end
  end

  describe 'Complete workflow: Clash lifecycle with work packages' do
    let!(:clash) do
      create(:bim_clash, :critical, :new,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'duct-201',
             overlap_volume: 250.5)
    end

    it 'manages clash from detection through work package creation to resolution' do
      # Step 1: Verify clash is new
      expect(clash.status).to eq('new')
      expect(clash.work_package).to be_nil

      # Step 2: Create work package for clash
      work_package = clash.create_work_package!(
        type: work_package_type,
        assigned_to: user
      )

      expect(work_package).to be_persisted
      expect(work_package.subject).to include('Resolve clash')
      expect(work_package.description).to include('IfcWall')
      expect(work_package.description).to include('IfcFlowSegment')
      expect(work_package.priority.name).to eq('Immediate') # Critical priority

      # Step 3: Assign clash to user and activate
      clash.assign!(user)

      expect(clash.reload.assigned_to).to eq(user)
      expect(clash.status).to eq('active')

      # Step 4: Resolve clash
      clash.resolve!(
        user: user,
        resolution_type: :redesign,
        comment: 'Duct rerouted to avoid structural wall'
      )

      expect(clash.reload.status).to eq('resolved')
      expect(clash.resolved_by).to eq(user)
      expect(clash.resolution_type).to eq('redesign')
      expect(clash.resolved_at).to be_present

      # Step 5: Close clash
      clash.close!

      expect(clash.reload.status).to eq('closed')
    end
  end

  describe 'Complete workflow: Bulk operations' do
    before do
      create_list(:bim_clash, 5, :critical, :new, ifc_model: ifc_model)
      create_list(:bim_clash, 3, :major, :new, ifc_model: ifc_model)
      create_list(:bim_clash, 2, :minor, :new, ifc_model: ifc_model)
    end

    it 'performs bulk status updates on filtered clashes' do
      service = Bim::BatchClashDetectionService.new

      # Update all critical clashes to active
      result = service.bulk_status_update(
        ifc_model: ifc_model,
        criteria: { current_status: :new, severity: :critical },
        new_status: :active
      )

      expect(result).to be_success
      expect(result.result[:updated_count]).to eq(5)

      # Verify updates
      expect(Bim::Clash.where(severity: :critical, status: :active).count).to eq(5)
      expect(Bim::Clash.where(severity: :major, status: :new).count).to eq(3)
    end

    it 'cleans up old resolved clashes' do
      # Create old resolved clashes
      create_list(:bim_clash, 3, :resolved,
                  ifc_model: ifc_model,
                  detected_at: 100.days.ago)

      service = Bim::BatchClashDetectionService.new
      result = service.cleanup_old_clashes(
        ifc_model: ifc_model,
        older_than: 90,
        statuses: [:resolved],
        action: :archive
      )

      expect(result).to be_success
      expect(result.result[:count]).to eq(3)

      # Verify clashes were archived (status changed to closed)
      expect(Bim::Clash.where(status: :closed).count).to eq(3)
    end
  end

  describe 'Complete workflow: Clash severity scoring' do
    it 'calculates severity scores correctly' do
      critical_hard = create(:bim_clash, :hard, :critical,
                             ifc_model: ifc_model,
                             overlap_volume: 500.0)

      major_soft = create(:bim_clash, :soft, :major,
                          ifc_model: ifc_model)

      minor_clearance = create(:bim_clash, :clearance, :minor,
                               ifc_model: ifc_model)

      # Critical hard clash should have highest score
      expect(critical_hard.severity_score).to be > major_soft.severity_score
      expect(major_soft.severity_score).to be > minor_clearance.severity_score

      # Critical hard with overlap should have bonus
      expect(critical_hard.severity_score).to be >= 100
    end
  end

  describe 'Error handling and validation' do
    it 'prevents duplicate clashes' do
      create(:bim_clash, ifc_model: ifc_model,
                         element_a_id: 'wall-101',
                         element_b_id: 'wall-102')

      post '/api/v3/bim/clashes', params: {
        clash: {
          ifc_model_id: ifc_model.id,
          element_a_id: 'wall-101',
          element_b_id: 'wall-102',
          clash_type: 'hard',
          severity: 'critical'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include('already been taken')
    end

    it 'validates element IDs are different' do
      post '/api/v3/bim/clashes', params: {
        clash: {
          ifc_model_id: ifc_model.id,
          element_a_id: 'wall-101',
          element_b_id: 'wall-101',
          clash_type: 'hard',
          severity: 'critical'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include('must be different')
    end

    it 'requires approval comment when approving' do
      clash = create(:bim_clash, :new, ifc_model: ifc_model)

      post "/api/v3/bim/clashes/#{clash.id}/approve"

      expect(response).to have_http_status(:bad_request)
    end

    it 'requires resolution type when resolving' do
      clash = create(:bim_clash, :active, ifc_model: ifc_model)

      post "/api/v3/bim/clashes/#{clash.id}/resolve", params: {
        comment: 'Fixed'
      }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'Complete workflow: Clash trends over time' do
    before do
      # Create clashes at different time periods
      create_list(:bim_clash, 5, :critical,
                  ifc_model: ifc_model,
                  detected_at: 1.week.ago)
      create_list(:bim_clash, 3, :major,
                  ifc_model: ifc_model,
                  detected_at: 2.weeks.ago)
      create_list(:bim_clash, 2, :minor,
                  ifc_model: ifc_model,
                  detected_at: 3.weeks.ago)
    end

    it 'analyzes clash trends over time' do
      service = Bim::BatchClashDetectionService.new
      result = service.clash_trends(
        ifc_model: ifc_model,
        period: :weekly,
        limit: 4
      )

      expect(result).to be_success
      trends = result.result[:trends]

      expect(trends).not_to be_empty
      expect(trends.first).to have_key(:date)
      expect(trends.first).to have_key(:total)
      expect(trends.first).to have_key(:by_severity)
    end
  end
end
