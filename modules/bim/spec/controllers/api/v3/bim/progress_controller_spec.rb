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

RSpec.describe API::V3::Bim::ProgressController, type: :controller do
  let(:user) { create(:user) }
  let(:model) { create(:ifc_model) }
  let(:progress) { create(:element_progress, ifc_model: model) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(model).to receive(:metadata).and_return({
                                                     'elements' => {
                                                       'wall-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 1' } }
                                                     }
                                                   })
  end

  describe 'GET #index' do
    let!(:progress1) { create(:element_progress, ifc_model: model) }
    let!(:progress2) { create(:element_progress, ifc_model: model) }

    it 'requires model_id parameter' do
      get :index
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to include('model_id')
    end

    it 'returns progress for specified model' do
      get :index, params: { model_id: model.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(2)
    end

    it 'filters by status' do
      completed = create(:element_progress, :completed, ifc_model: model)
      get :index, params: { model_id: model.id, status: 'completed' }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(1)
      expect(json['progress'].first['id']).to eq(completed.id)
    end

    it 'filters by element_type' do
      wall = create(:element_progress, :wall, ifc_model: model)
      door = create(:element_progress, :door, ifc_model: model)

      get :index, params: { model_id: model.id, element_type: 'IfcWall' }

      json = JSON.parse(response.body)
      wall_ids = json['progress'].map { |p| p['id'] }
      expect(wall_ids).to include(wall.id)
      expect(wall_ids).not_to include(door.id)
    end

    it 'filters by work_package_id' do
      wp = create(:work_package)
      with_wp = create(:element_progress, ifc_model: model, work_package: wp)

      get :index, params: { model_id: model.id, work_package_id: wp.id }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(1)
      expect(json['progress'].first['id']).to eq(with_wp.id)
    end

    it 'filters by baseline_id' do
      baseline = create(:progress_baseline, ifc_model: model)
      baseline_progress = create(:element_progress, ifc_model: model, baseline: baseline)

      get :index, params: { model_id: model.id, baseline_id: baseline.id }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(1)
      expect(json['progress'].first['id']).to eq(baseline_progress.id)
    end

    it 'defaults to current progress (no baseline)' do
      create(:element_progress, :with_baseline, ifc_model: model)

      get :index, params: { model_id: model.id }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(2) # Only current (no baseline)
    end

    it 'supports pagination' do
      get :index, params: { model_id: model.id, page: 1, per_page: 1 }

      json = JSON.parse(response.body)
      expect(json['progress'].size).to eq(1)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(1)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :index, params: { model_id: model.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    it 'returns the element progress' do
      get :show, params: { id: progress.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(progress.id)
      expect(json['element_id']).to eq(progress.element_id)
    end

    it 'includes detailed information' do
      progress_with_schedule = create(:element_progress, :with_schedule, :in_progress)
      get :show, params: { id: progress_with_schedule.id }

      json = JSON.parse(response.body)
      expect(json).to have_key('planned_start')
      expect(json).to have_key('planned_finish')
      expect(json).to have_key('schedule_variance_days')
      expect(json).to have_key('progress_color')
    end

    it 'returns not found for non-existent progress' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :show, params: { id: progress.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        ifc_model_id: model.id,
        element_id: 'wall-1',
        percent_complete: 50
      }
    end

    it 'requires ifc_model_id and element_id' do
      post :create, params: { percent_complete: 50 }
      expect(response).to have_http_status(:bad_request)
    end

    it 'creates new element progress' do
      expect do
        post :create, params: valid_params
      end.to change(Bim::ElementProgress, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['element_id']).to eq('wall-1')
      expect(json['percent_complete']).to eq(50)
    end

    it 'initializes from IFC metadata' do
      post :create, params: valid_params

      progress = Bim::ElementProgress.last
      expect(progress.element_type).to eq('IfcWall')
      expect(progress.element_name).to eq('Wall 1')
    end

    it 'updates existing progress if element exists' do
      create(:element_progress, ifc_model: model, element_id: 'wall-1', percent_complete: 25)

      expect do
        post :create, params: valid_params
      end.not_to change(Bim::ElementProgress, :count)

      progress = Bim::ElementProgress.find_by(element_id: 'wall-1')
      expect(progress.percent_complete).to eq(50)
    end

    it 'sets status based on percent_complete' do
      post :create, params: valid_params.merge(percent_complete: 100)
      progress = Bim::ElementProgress.last
      expect(progress.status).to eq('completed')
    end

    it 'allows explicit status override' do
      post :create, params: valid_params.merge(status: 'on_hold')
      progress = Bim::ElementProgress.last
      expect(progress.status).to eq('on_hold')
    end

    it 'links to work package if provided' do
      wp = create(:work_package)
      post :create, params: valid_params.merge(work_package_id: wp.id)

      progress = Bim::ElementProgress.last
      expect(progress.work_package).to eq(wp)
    end

    it 'returns not found for non-existent model' do
      post :create, params: valid_params.merge(ifc_model_id: 99999)
      expect(response).to have_http_status(:not_found)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        post :create, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:progress) { create(:element_progress, ifc_model: model, percent_complete: 25) }

    it 'updates progress percentage' do
      patch :update, params: { id: progress.id, percent_complete: 75 }
      expect(response).to have_http_status(:ok)
      expect(progress.reload.percent_complete).to eq(75)
    end

    it 'updates status based on progress' do
      patch :update, params: { id: progress.id, percent_complete: 100 }
      expect(progress.reload.status).to eq('completed')
    end

    it 'updates other attributes' do
      patch :update, params: {
        id: progress.id,
        planned_start: Date.current,
        planned_finish: 10.days.from_now
      }

      expect(response).to have_http_status(:ok)
      expect(progress.reload.planned_start).to eq(Date.current)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        patch :update, params: { id: progress.id, percent_complete: 50 }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the progress' do
      progress_to_delete = create(:element_progress)
      expect do
        delete :destroy, params: { id: progress_to_delete.id }
      end.to change(Bim::ElementProgress, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        delete :destroy, params: { id: progress.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #bulk_update' do
    let(:updates) do
      [
        { element_id: 'wall-1', percent_complete: 50 },
        { element_id: 'wall-2', percent_complete: 75 }
      ]
    end

    it 'requires model_id and updates' do
      post :bulk_update
      expect(response).to have_http_status(:bad_request)
    end

    it 'updates multiple elements' do
      post :bulk_update, params: { model_id: model.id, updates: updates }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['updated_count']).to eq(2)
      expect(json['progress'].size).to eq(2)
    end

    it 'creates elements if they do not exist' do
      expect do
        post :bulk_update, params: { model_id: model.id, updates: updates }
      end.to change(Bim::ElementProgress, :count).by(2)
    end

    it 'returns errors for invalid updates' do
      invalid_updates = [
        { element_id: 'wall-1', percent_complete: 150 } # Invalid
      ]

      post :bulk_update, params: { model_id: model.id, updates: invalid_updates }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rolls back all changes on any failure' do
      mixed_updates = [
        { element_id: 'wall-1', percent_complete: 50 },
        { element_id: 'wall-2', percent_complete: 150 } # Invalid
      ]

      expect do
        post :bulk_update, params: { model_id: model.id, updates: mixed_updates }
      end.not_to change(Bim::ElementProgress, :count)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        post :bulk_update, params: { model_id: model.id, updates: updates }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #sync_work_packages' do
    let(:wp1) { create(:work_package, done_ratio: 60) }
    let(:wp2) { create(:work_package, done_ratio: 100) }

    before do
      create(:element_progress, ifc_model: model, work_package: wp1, percent_complete: 0)
      create(:element_progress, ifc_model: model, work_package: wp2, percent_complete: 0)
      create(:element_progress, ifc_model: model, percent_complete: 0) # No WP
    end

    it 'requires model_id' do
      post :sync_work_packages
      expect(response).to have_http_status(:bad_request)
    end

    it 'syncs progress from work packages' do
      post :sync_work_packages, params: { model_id: model.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['synced_count']).to eq(2)
    end

    it 'updates element progress to match work package' do
      post :sync_work_packages, params: { model_id: model.id }

      elem1 = Bim::ElementProgress.find_by(work_package: wp1)
      expect(elem1.percent_complete).to eq(60)

      elem2 = Bim::ElementProgress.find_by(work_package: wp2)
      expect(elem2.percent_complete).to eq(100)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        post :sync_work_packages, params: { model_id: model.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #statistics' do
    before do
      create(:element_progress, :completed, ifc_model: model)
      create(:element_progress, :in_progress, ifc_model: model)
      create(:element_progress, :planned, ifc_model: model)
    end

    it 'requires model_id' do
      get :statistics
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns model progress statistics' do
      get :statistics, params: { model_id: model.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['total_elements']).to eq(3)
      expect(json['completed_elements']).to eq(1)
      expect(json['in_progress_elements']).to eq(1)
      expect(json['planned_elements']).to eq(1)
      expect(json['overall_progress']).to be_present
      expect(json['average_progress']).to be_present
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :statistics, params: { model_id: model.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
