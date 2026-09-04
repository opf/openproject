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

RSpec.describe Api::V3::Bim::ComparisonsController, type: :controller do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:model1) { create(:ifc_model, project: project, title: 'Model V1') }
  let(:model2) { create(:ifc_model, project: project, title: 'Model V2') }

  before do
    login_as(user)
  end

  describe 'GET #index' do
    let!(:comparison1) { create(:bim_model_comparison, model1: model1, model2: model2) }
    let!(:comparison2) { create(:bim_model_comparison, model1: model2, model2: model1) }
    let!(:other_comparison) { create(:bim_model_comparison) }

    it 'returns all comparisons' do
      get :index, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comparisons'].size).to be >= 2
    end

    it 'filters by model_id' do
      get :index, params: { model_id: model1.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comparisons'].map { |c| c['id'] }).to contain_exactly(comparison1.id, comparison2.id)
    end

    it 'filters by status' do
      comparison1.update!(status: :completed)

      get :index, params: { status: 'completed' }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comparisons'].all? { |c| c['status'] == 'completed' }).to be true
    end

    it 'paginates results' do
      create_list(:bim_model_comparison, 25)

      get :index, params: { page: 1, per_page: 10 }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comparisons'].size).to eq(10)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(10)
    end
  end

  describe 'GET #show' do
    let(:comparison) { create(:bim_model_comparison, :with_changes, model1: model1, model2: model2) }

    it 'returns comparison details' do
      get :show, params: { id: comparison.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(comparison.id)
      expect(json['model1_id']).to eq(model1.id)
      expect(json['model2_id']).to eq(model2.id)
      expect(json['changes_data']).to be_present
      expect(json['statistics']).to be_present
    end

    it 'returns 404 for non-existent comparison' do
      get :show, params: { id: 99999 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    before do
      allow(model1).to receive(:metadata).and_return({
                                                        'elements' => {
                                                          'wall-1' => { 'properties' => { 'type' => 'IfcWall' } }
                                                        }
                                                      })
      allow(model2).to receive(:metadata).and_return({
                                                        'elements' => {
                                                          'wall-2' => { 'properties' => { 'type' => 'IfcWall' } }
                                                        }
                                                      })
    end

    it 'creates a new comparison' do
      expect do
        post :create, params: {
          model1_id: model1.id,
          model2_id: model2.id,
          name: 'Test Comparison'
        }, format: :json
      end.to change(Bim::ModelComparison, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['model1_id']).to eq(model1.id)
      expect(json['model2_id']).to eq(model2.id)
      expect(json['name']).to eq('Test Comparison')
    end

    it 'runs comparison automatically' do
      post :create, params: {
        model1_id: model1.id,
        model2_id: model2.id
      }, format: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('completed')
      expect(json['added_count']).to be >= 0
    end

    it 'accepts comparison options' do
      post :create, params: {
        model1_id: model1.id,
        model2_id: model2.id,
        options: {
          detect_geometry_changes: false,
          ignore_properties: ['height']
        }
      }, format: :json

      expect(response).to have_http_status(:created)
    end

    it 'requires model1_id' do
      post :create, params: { model2_id: model2.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('model1_id')
    end

    it 'requires model2_id' do
      post :create, params: { model1_id: model1.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('model2_id')
    end
  end

  describe 'PATCH #update' do
    let(:comparison) { create(:bim_model_comparison, model1: model1, model2: model2) }

    it 'updates comparison name' do
      patch :update, params: {
        id: comparison.id,
        name: 'Updated Name'
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(comparison.reload.name).to eq('Updated Name')
    end

    it 'updates comparison description' do
      patch :update, params: {
        id: comparison.id,
        description: 'Updated description'
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(comparison.reload.description).to eq('Updated description')
    end

    it 'updates comparison status' do
      patch :update, params: {
        id: comparison.id,
        status: 'completed'
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(comparison.reload.status).to eq('completed')
    end
  end

  describe 'DELETE #destroy' do
    let!(:comparison) { create(:bim_model_comparison, model1: model1, model2: model2) }

    it 'deletes the comparison' do
      expect do
        delete :destroy, params: { id: comparison.id }, format: :json
      end.to change(Bim::ModelComparison, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent comparison' do
      delete :destroy, params: { id: 99999 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #approve' do
    let(:comparison) { create(:bim_model_comparison, :completed, model1: model1, model2: model2) }

    it 'approves the comparison' do
      post :approve, params: {
        id: comparison.id,
        comment: 'Changes approved for implementation'
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('approved')
      expect(json['approved_by_id']).to eq(user.id)
      expect(json['status_comment']).to eq('Changes approved for implementation')
    end

    it 'requires comment parameter' do
      post :approve, params: { id: comparison.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('comment')
    end

    it 'returns error if approval fails' do
      allow_any_instance_of(Bim::ModelComparison).to receive(:approve!).and_return(false)

      post :approve, params: {
        id: comparison.id,
        comment: 'Test'
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #reject' do
    let(:comparison) { create(:bim_model_comparison, :completed, model1: model1, model2: model2) }

    it 'rejects the comparison' do
      post :reject, params: {
        id: comparison.id,
        comment: 'Too many structural changes'
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('rejected')
      expect(json['approved_by_id']).to eq(user.id)
      expect(json['status_comment']).to eq('Too many structural changes')
    end

    it 'requires comment parameter' do
      post :reject, params: { id: comparison.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('comment')
    end

    it 'returns error if rejection fails' do
      allow_any_instance_of(Bim::ModelComparison).to receive(:reject!).and_return(false)

      post :reject, params: {
        id: comparison.id,
        comment: 'Test'
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
