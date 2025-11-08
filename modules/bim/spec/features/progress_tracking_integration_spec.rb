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

RSpec.describe 'Progress Tracking Integration', type: :feature do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:model) { create(:ifc_model, project: project, title: 'Office Building') }

  before do
    login_as(user)

    # Mock IFC metadata
    allow(model).to receive(:metadata).and_return({
                                                     'elements' => {
                                                       'wall-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'North Wall' } },
                                                       'wall-2' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'South Wall' } },
                                                       'door-1' => { 'properties' => { 'type' => 'IfcDoor', 'name' => 'Main Entrance' } }
                                                     }
                                                   })
  end

  describe 'Complete workflow: Progress tracking lifecycle' do
    it 'creates, updates, and completes element progress' do
      # Step 1: Create initial progress
      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-1',
        percent_complete: 0
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      progress_id = json['id']

      expect(json['status']).to eq('planned')
      expect(json['percent_complete']).to eq(0)
      expect(json['element_name']).to eq('North Wall')
      expect(json['element_type']).to eq('IfcWall')

      # Step 2: Start work (update to 25%)
      patch "/api/v3/bim/progress/#{progress_id}", params: {
        percent_complete: 25
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['status']).to eq('in_progress')
      expect(json['percent_complete']).to eq(25)
      expect(json['actual_start']).to eq(Date.current.to_s)

      # Step 3: Continue work (update to 75%)
      patch "/api/v3/bim/progress/#{progress_id}", params: {
        percent_complete: 75
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['percent_complete']).to eq(75)

      # Step 4: Complete work
      patch "/api/v3/bim/progress/#{progress_id}", params: {
        percent_complete: 100
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['status']).to eq('completed')
      expect(json['percent_complete']).to eq(100)
      expect(json['actual_finish']).to eq(Date.current.to_s)

      # Step 5: Verify statistics
      get '/api/v3/bim/progress/statistics', params: { model_id: model.id }

      expect(response).to have_http_status(:ok)
      stats = JSON.parse(response.body)

      expect(stats['total_elements']).to eq(1)
      expect(stats['completed_elements']).to eq(1)
      expect(stats['overall_progress']).to eq(100.0)
    end
  end

  describe 'Complete workflow: Bulk progress updates' do
    it 'updates multiple elements in a single transaction' do
      updates = [
        { element_id: 'wall-1', percent_complete: 50 },
        { element_id: 'wall-2', percent_complete: 75 },
        { element_id: 'door-1', percent_complete: 100 }
      ]

      post '/api/v3/bim/progress/bulk_update', params: {
        model_id: model.id,
        updates: updates
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['updated_count']).to eq(3)
      expect(json['progress'].size).to eq(3)

      # Verify individual updates
      get '/api/v3/bim/progress', params: { model_id: model.id }
      json = JSON.parse(response.body)

      wall1 = json['progress'].find { |p| p['element_id'] == 'wall-1' }
      expect(wall1['percent_complete']).to eq(50)
      expect(wall1['status']).to eq('in_progress')

      door1 = json['progress'].find { |p| p['element_id'] == 'door-1' }
      expect(door1['percent_complete']).to eq(100)
      expect(door1['status']).to eq('completed')
    end

    it 'rolls back all changes if any update fails' do
      updates = [
        { element_id: 'wall-1', percent_complete: 50 },
        { element_id: 'wall-2', percent_complete: 150 } # Invalid
      ]

      post '/api/v3/bim/progress/bulk_update', params: {
        model_id: model.id,
        updates: updates
      }

      expect(response).to have_http_status(:unprocessable_entity)

      # Verify no elements were created
      get '/api/v3/bim/progress', params: { model_id: model.id }
      json = JSON.parse(response.body)
      expect(json['progress']).to be_empty
    end
  end

  describe 'Complete workflow: Work package synchronization' do
    let(:wp1) { create(:work_package, project: project, done_ratio: 60) }
    let(:wp2) { create(:work_package, project: project, done_ratio: 100) }
    let(:wp3_closed) { create(:work_package, project: project, status: create(:status, is_closed: true)) }

    before do
      # Create progress linked to work packages
      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-1',
        percent_complete: 0,
        work_package_id: wp1.id
      }

      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-2',
        percent_complete: 0,
        work_package_id: wp2.id
      }

      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'door-1',
        percent_complete: 0,
        work_package_id: wp3_closed.id
      }
    end

    it 'syncs progress from work package completion' do
      post '/api/v3/bim/progress/sync_work_packages', params: {
        model_id: model.id
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['synced_count']).to eq(3)

      # Verify synced values
      get '/api/v3/bim/progress', params: { model_id: model.id }
      json = JSON.parse(response.body)

      wall1 = json['progress'].find { |p| p['element_id'] == 'wall-1' }
      expect(wall1['percent_complete']).to eq(60)

      wall2 = json['progress'].find { |p| p['element_id'] == 'wall-2' }
      expect(wall2['percent_complete']).to eq(100)

      door1 = json['progress'].find { |p| p['element_id'] == 'door-1' }
      expect(door1['percent_complete']).to eq(100) # Closed status
    end
  end

  describe 'Complete workflow: Baseline management and comparison' do
    before do
      # Create initial progress
      post '/api/v3/bim/progress/bulk_update', params: {
        model_id: model.id,
        updates: [
          { element_id: 'wall-1', percent_complete: 25 },
          { element_id: 'wall-2', percent_complete: 50 }
        ]
      }
    end

    it 'creates baseline, advances progress, and compares' do
      # Step 1: Create baseline snapshot
      post '/api/v3/bim/baselines', params: {
        ifc_model_id: model.id,
        name: 'Week 1 Baseline',
        description: 'End of week 1 progress',
        snapshot_date: Date.current,
        create_snapshot: true
      }

      expect(response).to have_http_status(:created)
      baseline_json = JSON.parse(response.body)
      baseline_id = baseline_json['id']

      expect(baseline_json['total_elements']).to eq(2)
      expect(baseline_json['overall_progress']).to eq(37.5) # (25 + 50) / 2

      # Step 2: Advance current progress
      post '/api/v3/bim/progress/bulk_update', params: {
        model_id: model.id,
        updates: [
          { element_id: 'wall-1', percent_complete: 75 },
          { element_id: 'wall-2', percent_complete: 100 }
        ]
      }

      # Step 3: Compare to baseline
      get "/api/v3/bim/baselines/#{baseline_id}/compare"

      expect(response).to have_http_status(:ok)
      comparison = JSON.parse(response.body)

      expect(comparison['baseline_name']).to eq('Week 1 Baseline')
      expect(comparison['baseline_progress']).to eq(37.5)
      expect(comparison['current_progress']).to eq(87.5) # (75 + 100) / 2
      expect(comparison['variance']).to eq(50.0)

      # Verify element-level changes
      expect(comparison['element_changes'].size).to eq(2)

      wall1_change = comparison['element_changes'].find { |c| c['element_id'] == 'wall-1' }
      expect(wall1_change['baseline_progress']).to eq(25)
      expect(wall1_change['current_progress']).to eq(75)
      expect(wall1_change['variance']).to eq(50)
    end

    it 'sets baseline as current' do
      # Create two baselines
      post '/api/v3/bim/baselines', params: {
        ifc_model_id: model.id,
        name: 'Baseline 1',
        snapshot_date: Date.current
      }
      baseline1_id = JSON.parse(response.body)['id']

      post '/api/v3/bim/baselines', params: {
        ifc_model_id: model.id,
        name: 'Baseline 2',
        snapshot_date: Date.current
      }
      baseline2_id = JSON.parse(response.body)['id']

      # Set baseline 2 as current
      post "/api/v3/bim/baselines/#{baseline2_id}/set_current"

      expect(response).to have_http_status(:ok)

      # Verify only baseline 2 is current
      get '/api/v3/bim/baselines', params: { model_id: model.id, is_current: 'true' }
      json = JSON.parse(response.body)

      expect(json['baselines'].size).to eq(1)
      expect(json['baselines'].first['id']).to eq(baseline2_id)
    end
  end

  describe 'Complete workflow: Schedule variance tracking' do
    it 'tracks delayed and ahead-of-schedule elements' do
      # Create element with planned dates (delayed)
      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-1',
        percent_complete: 100,
        planned_start: 20.days.ago.to_date,
        planned_finish: 5.days.ago.to_date,
        actual_start: 20.days.ago.to_date,
        actual_finish: Date.current
      }

      get '/api/v3/bim/progress', params: { model_id: model.id }
      json = JSON.parse(response.body)
      wall1 = json['progress'].first

      expect(wall1['schedule_variance_days']).to eq(5) # Finished 5 days late
      expect(wall1['delayed']).to be true

      # Create element ahead of schedule
      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-2',
        percent_complete: 100,
        planned_start: 10.days.ago.to_date,
        planned_finish: 5.days.from_now.to_date,
        actual_start: 10.days.ago.to_date,
        actual_finish: Date.current
      }

      get '/api/v3/bim/progress', params: { model_id: model.id, element_id: 'wall-2' }
      json = JSON.parse(response.body)
      wall2 = json['progress'].last

      expect(wall2['schedule_variance_days']).to eq(-5) # Finished 5 days early
      expect(wall2['ahead_of_schedule']).to be true

      # Verify statistics
      get '/api/v3/bim/progress/statistics', params: { model_id: model.id }
      stats = JSON.parse(response.body)

      expect(stats['delayed_count']).to eq(1)
      expect(stats['ahead_count']).to eq(1)
    end
  end

  describe 'Complete workflow: Filtering and pagination' do
    before do
      # Create diverse progress records
      post '/api/v3/bim/progress/bulk_update', params: {
        model_id: model.id,
        updates: [
          { element_id: 'wall-1', percent_complete: 0 },   # Planned
          { element_id: 'wall-2', percent_complete: 50 },  # In progress
          { element_id: 'door-1', percent_complete: 100 }  # Completed
        ]
      }
    end

    it 'filters by status' do
      get '/api/v3/bim/progress', params: { model_id: model.id, status: 'completed' }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(1)
      expect(json['progress'].first['element_id']).to eq('door-1')
    end

    it 'filters by element type' do
      get '/api/v3/bim/progress', params: { model_id: model.id, element_type: 'IfcWall' }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(2)
      json['progress'].each do |p|
        expect(p['element_type']).to eq('IfcWall')
      end
    end

    it 'supports pagination' do
      get '/api/v3/bim/progress', params: { model_id: model.id, page: 1, per_page: 2 }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(2)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(2)
      expect(json['total']).to eq(3)
    end
  end

  describe 'Error handling and validation' do
    it 'validates percent_complete range' do
      post '/api/v3/bim/progress', params: {
        ifc_model_id: model.id,
        element_id: 'wall-1',
        percent_complete: 150
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'validates status-progress consistency' do
      progress = create(:element_progress, ifc_model: model, status: :planned, percent_complete: 0)

      # Try to set completed status with incomplete progress
      patch "/api/v3/bim/progress/#{progress.id}", params: {
        status: 'completed',
        percent_complete: 50
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'requires model_id for operations' do
      post '/api/v3/bim/progress/bulk_update', params: {
        updates: [{ element_id: 'wall-1', percent_complete: 50 }]
      }

      expect(response).to have_http_status(:bad_request)
    end

    it 'prevents duplicate current baselines per model' do
      create(:progress_baseline, :current, ifc_model: model)

      post '/api/v3/bim/baselines', params: {
        ifc_model_id: model.id,
        name: 'Another Current',
        is_current: true
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
