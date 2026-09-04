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

RSpec.describe API::V3::Bim::BaselinesController, type: :controller do
  let(:user) { create(:user) }
  let(:model) { create(:ifc_model) }
  let(:baseline) { create(:progress_baseline, ifc_model: model, created_by: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:baseline1) { create(:progress_baseline, ifc_model: model) }
    let!(:baseline2) { create(:progress_baseline, ifc_model: model) }
    let!(:other_baseline) { create(:progress_baseline) }

    it 'returns all baselines' do
      get :index
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['baselines'].size).to eq(3)
    end

    it 'filters by model_id' do
      get :index, params: { model_id: model.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['baselines'].size).to eq(2)
    end

    it 'filters by is_current' do
      current = create(:progress_baseline, :current, ifc_model: model)
      get :index, params: { is_current: 'true' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['baselines'].size).to eq(1)
      expect(json['baselines'].first['id']).to eq(current.id)
    end

    it 'supports pagination' do
      get :index, params: { page: 1, per_page: 2 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['baselines'].size).to eq(2)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(2)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    it 'returns the baseline' do
      get :show, params: { id: baseline.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(baseline.id)
      expect(json['name']).to eq(baseline.name)
    end

    it 'includes detailed information' do
      baseline_with_stats = create(:progress_baseline, :with_statistics)
      get :show, params: { id: baseline_with_stats.id }
      json = JSON.parse(response.body)
      expect(json).to have_key('statistics')
      expect(json).to have_key('statistics_by_type')
      expect(json).to have_key('statistics_by_status')
    end

    it 'returns not found for non-existent baseline' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :show, params: { id: baseline.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        ifc_model_id: model.id,
        name: 'Q1 2025 Baseline',
        description: 'First quarter baseline',
        snapshot_date: Date.current
      }
    end

    it 'creates a new baseline' do
      expect do
        post :create, params: valid_params
      end.to change(Bim::ProgressBaseline, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Q1 2025 Baseline')
    end

    it 'sets created_by to current user' do
      post :create, params: valid_params
      baseline = Bim::ProgressBaseline.last
      expect(baseline.created_by).to eq(user)
    end

    it 'creates snapshot if requested' do
      create(:element_progress, :completed, ifc_model: model)

      post :create, params: valid_params.merge(create_snapshot: true)

      baseline = Bim::ProgressBaseline.last
      expect(baseline.element_progresses.count).to eq(1)
    end

    it 'returns errors for invalid data' do
      post :create, params: { name: '' }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json).to have_key('errors')
    end

    it 'accepts params in baseline key' do
      post :create, params: { baseline: valid_params }
      expect(response).to have_http_status(:created)
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
    it 'updates the baseline' do
      patch :update, params: { id: baseline.id, baseline: { name: 'Updated Name' } }
      expect(response).to have_http_status(:ok)
      expect(baseline.reload.name).to eq('Updated Name')
    end

    it 'returns errors for invalid data' do
      patch :update, params: { id: baseline.id, baseline: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        patch :update, params: { id: baseline.id, baseline: { name: 'New' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the baseline' do
      baseline_to_delete = create(:progress_baseline)
      expect do
        delete :destroy, params: { id: baseline_to_delete.id }
      end.to change(Bim::ProgressBaseline, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        delete :destroy, params: { id: baseline.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #snapshot' do
    before do
      create(:element_progress, :completed, ifc_model: model)
      create(:element_progress, :in_progress, ifc_model: model)
    end

    it 'creates snapshot of current progress' do
      expect do
        post :snapshot, params: { id: baseline.id }
      end.to change { baseline.element_progresses.count }.from(0).to(2)

      expect(response).to have_http_status(:ok)
    end

    it 'updates baseline statistics' do
      post :snapshot, params: { id: baseline.id }
      baseline.reload
      expect(baseline.total_elements).to eq(2)
      expect(baseline.completed_elements).to eq(1)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        post :snapshot, params: { id: baseline.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #set_current' do
    let!(:old_current) { create(:progress_baseline, :current, ifc_model: model) }

    it 'sets baseline as current' do
      post :set_current, params: { id: baseline.id }
      expect(response).to have_http_status(:ok)
      expect(baseline.reload.is_current).to be true
    end

    it 'unsets previous current baseline' do
      post :set_current, params: { id: baseline.id }
      expect(old_current.reload.is_current).to be false
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        post :set_current, params: { id: baseline.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #compare' do
    before do
      # Create baseline snapshot
      create(:element_progress, ifc_model: model, element_id: 'wall-1', baseline: baseline, percent_complete: 0)

      # Create current progress (advanced)
      create(:element_progress, ifc_model: model, element_id: 'wall-1', percent_complete: 50)
    end

    it 'compares baseline to current progress' do
      get :compare, params: { id: baseline.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json).to have_key('baseline_name')
      expect(json).to have_key('current_progress')
      expect(json).to have_key('variance')
      expect(json).to have_key('element_changes')
    end

    it 'includes element-level changes' do
      get :compare, params: { id: baseline.id }
      json = JSON.parse(response.body)

      expect(json['element_changes'].size).to eq(1)
      expect(json['element_changes'].first['element_id']).to eq('wall-1')
      expect(json['element_changes'].first['variance']).to eq(50)
    end

    context 'when not logged in' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :compare, params: { id: baseline.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
