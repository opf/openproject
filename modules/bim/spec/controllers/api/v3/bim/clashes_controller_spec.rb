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

RSpec.describe Api::V3::Bim::ClashesController, type: :controller do
  let(:user) { create(:user, global_permissions: [:view_ifc_models, :manage_ifc_models]) }
  let(:project) { create(:project) }
  let(:ifc_model) { create(:ifc_model, project: project, title: 'Test Building') }
  let(:work_package) { create(:work_package, project: project) }

  before do
    login_as(user)

    # Mock IFC model metadata with bounding boxes
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-101' => {
                                                             'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 101' },
                                                             'geometry' => {
                                                               'hash' => 'abc123',
                                                               'boundingBox' => {
                                                                 'min' => [0.0, 0.0, 0.0],
                                                                 'max' => [5000.0, 200.0, 3000.0]
                                                               }
                                                             }
                                                           },
                                                           'wall-102' => {
                                                             'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 102' },
                                                             'geometry' => {
                                                               'hash' => 'def456',
                                                               'boundingBox' => {
                                                                 'min' => [4900.0, 0.0, 0.0],
                                                                 'max' => [9900.0, 200.0, 3000.0]
                                                               }
                                                             }
                                                           },
                                                           'door-201' => {
                                                             'properties' => { 'type' => 'IfcDoor', 'name' => 'Door 201' },
                                                             'geometry' => {
                                                               'hash' => 'ghi789',
                                                               'boundingBox' => {
                                                                 'min' => [2000.0, 0.0, 0.0],
                                                                 'max' => [3000.0, 100.0, 2100.0]
                                                               }
                                                             }
                                                           }
                                                         }
                                                       })
  end

  describe 'GET #index' do
    let!(:clash1) do
      create(:bim_clash, :hard, :critical,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')
    end

    let!(:clash2) do
      create(:bim_clash, :soft, :major,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'door-201')
    end

    let!(:other_model_clash) do
      create(:bim_clash, ifc_model: create(:ifc_model))
    end

    it 'returns clashes for the specified IFC model' do
      get :index, params: { ifc_model_id: ifc_model.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(2)
      expect(json['clashes'].map { |c| c['id'] }).to contain_exactly(clash1.id, clash2.id)
    end

    it 'filters by status' do
      clash1.update!(status: :resolved)

      get :index, params: { ifc_model_id: ifc_model.id, status: 'new' }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(1)
      expect(json['clashes'].first['id']).to eq(clash2.id)
    end

    it 'filters by severity' do
      get :index, params: { ifc_model_id: ifc_model.id, severity: 'critical' }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(1)
      expect(json['clashes'].first['id']).to eq(clash1.id)
    end

    it 'filters by clash_type' do
      get :index, params: { ifc_model_id: ifc_model.id, clash_type: 'hard' }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(1)
      expect(json['clashes'].first['id']).to eq(clash1.id)
    end

    it 'filters by element_id' do
      get :index, params: { ifc_model_id: ifc_model.id, element_id: 'door-201' }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(1)
      expect(json['clashes'].first['id']).to eq(clash2.id)
    end

    it 'filters by work_package_id' do
      clash1.update!(work_package: work_package)

      get :index, params: { ifc_model_id: ifc_model.id, work_package_id: work_package.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(1)
      expect(json['clashes'].first['id']).to eq(clash1.id)
    end

    it 'paginates results' do
      # Create 25 more clashes
      25.times do |i|
        create(:bim_clash,
               ifc_model: ifc_model,
               element_a_id: "element-#{i}",
               element_b_id: "element-#{i + 100}")
      end

      get :index, params: { ifc_model_id: ifc_model.id, page: 1, per_page: 10 }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].size).to eq(10)
      expect(json['total']).to eq(27)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(10)
    end

    it 'requires ifc_model_id parameter' do
      get :index, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('ifc_model_id')
    end
  end

  describe 'GET #show' do
    let(:clash) do
      create(:bim_clash,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102',
             overlap_volume: 1250.5,
             clash_point: { x: 5000.0, y: 100.0, z: 1500.0 })
    end

    it 'returns the clash details' do
      get :show, params: { id: clash.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(clash.id)
      expect(json['element_a_id']).to eq('wall-101')
      expect(json['element_b_id']).to eq('wall-102')
      expect(json['overlap_volume']).to eq('1250.5')
      expect(json['clash_point']).to eq({ 'x' => 5000.0, 'y' => 100.0, 'z' => 1500.0 })
    end

    it 'returns 404 for non-existent clash' do
      get :show, params: { id: 99999 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        clash: {
          ifc_model_id: ifc_model.id,
          element_a_id: 'wall-101',
          element_b_id: 'wall-102',
          clash_type: 'hard',
          severity: 'critical',
          overlap_volume: 500.0,
          clash_point: { x: 5000.0, y: 100.0, z: 1500.0 }
        }
      }
    end

    it 'creates a new clash' do
      expect do
        post :create, params: valid_params, format: :json
      end.to change(Bim::Clash, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['element_a_id']).to eq('wall-101')
      expect(json['element_b_id']).to eq('wall-102')
      expect(json['clash_type']).to eq('hard')
    end

    it 'returns error for invalid params' do
      invalid_params = valid_params.deep_dup
      invalid_params[:clash][:element_a_id] = nil

      post :create, params: invalid_params, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include("can't be blank")
    end

    it 'returns error for duplicate clash' do
      create(:bim_clash,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')

      post :create, params: valid_params, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['message']).to include('already been taken')
    end
  end

  describe 'PATCH #update' do
    let(:clash) do
      create(:bim_clash, :new,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')
    end

    it 'updates clash status' do
      patch :update, params: { id: clash.id, clash: { status: 'active' } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.status).to eq('active')
    end

    it 'updates clash severity' do
      patch :update, params: { id: clash.id, clash: { severity: 'minor' } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.severity).to eq('minor')
    end

    it 'assigns clash to work package' do
      patch :update, params: { id: clash.id, clash: { work_package_id: work_package.id } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.work_package).to eq(work_package)
    end

    it 'assigns clash to user' do
      patch :update, params: { id: clash.id, clash: { assigned_to_id: user.id } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.assigned_to).to eq(user)
    end

    it 'returns error for invalid status transition' do
      clash.update!(status: :resolved)

      patch :update, params: { id: clash.id, clash: { status: 'new' } }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE #destroy' do
    let!(:clash) do
      create(:bim_clash,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')
    end

    it 'deletes the clash' do
      expect do
        delete :destroy, params: { id: clash.id }, format: :json
      end.to change(Bim::Clash, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent clash' do
      delete :destroy, params: { id: 99999 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #detect' do
    it 'detects all clashes in the model' do
      post :detect, params: {
        ifc_model_id: ifc_model.id,
        clearance_distance: 50.0,
        detect_hard_clashes: true,
        detect_soft_clashes: true
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['count']).to be >= 0
      expect(json['detection_run_id']).to be_present
      expect(json['clashes']).to be_an(Array)
    end

    it 'filters by element types' do
      post :detect, params: {
        ifc_model_id: ifc_model.id,
        element_types: ['IfcWall']
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes']).to be_an(Array)
    end

    it 'detects only hard clashes when specified' do
      post :detect, params: {
        ifc_model_id: ifc_model.id,
        detect_hard_clashes: true,
        detect_soft_clashes: false
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['clashes'].all? { |c| c['clash_type'] == 'hard' }).to be true
    end

    it 'requires ifc_model_id parameter' do
      post :detect, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('ifc_model_id')
    end
  end

  describe 'GET #statistics' do
    before do
      create(:bim_clash, :hard, :critical, :new, ifc_model: ifc_model, element_a_id: 'wall-101', element_b_id: 'wall-102')
      create(:bim_clash, :hard, :major, :active, ifc_model: ifc_model, element_a_id: 'wall-101', element_b_id: 'door-201')
      create(:bim_clash, :soft, :minor, :resolved, ifc_model: ifc_model, element_a_id: 'wall-102', element_b_id: 'door-201')
      create(:bim_clash, :clearance, :critical, :approved, ifc_model: ifc_model, element_a_id: 'wall-101', element_b_id: 'wall-102')
    end

    it 'returns clash statistics for the model' do
      get :statistics, params: { ifc_model_id: ifc_model.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['total_clashes']).to eq(4)
      expect(json['by_type']).to eq({
                                       'hard' => 2,
                                       'soft' => 1,
                                       'clearance' => 1,
                                       'workflow' => 0
                                     })
      expect(json['by_severity']).to eq({
                                          'critical' => 2,
                                          'major' => 1,
                                          'minor' => 1
                                        })
      expect(json['by_status']).to eq({
                                        'new' => 1,
                                        'active' => 1,
                                        'approved' => 1,
                                        'resolved' => 1,
                                        'closed' => 0
                                      })
    end

    it 'requires ifc_model_id parameter' do
      get :statistics, format: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'POST #approve' do
    let(:clash) do
      create(:bim_clash, :new,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')
    end

    it 'approves the clash' do
      post :approve, params: {
        id: clash.id,
        comment: 'Acceptable clearance violation'
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.status).to eq('approved')
      expect(clash.approved_by).to eq(user)
      expect(clash.approved_at).to be_present
      expect(clash.resolution_comment).to eq('Acceptable clearance violation')
    end

    it 'requires comment parameter' do
      post :approve, params: { id: clash.id }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('comment')
    end

    it 'returns error if clash already resolved' do
      clash.update!(status: :resolved)

      post :approve, params: { id: clash.id, comment: 'Test' }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #resolve' do
    let(:clash) do
      create(:bim_clash, :active,
             ifc_model: ifc_model,
             element_a_id: 'wall-101',
             element_b_id: 'wall-102')
    end

    it 'resolves the clash' do
      post :resolve, params: {
        id: clash.id,
        resolution_type: 'redesign',
        comment: 'Elements redesigned to eliminate overlap'
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(clash.reload.status).to eq('resolved')
      expect(clash.resolved_by).to eq(user)
      expect(clash.resolved_at).to be_present
      expect(clash.resolution_type).to eq('redesign')
      expect(clash.resolution_comment).to eq('Elements redesigned to eliminate overlap')
    end

    it 'requires resolution_type parameter' do
      post :resolve, params: { id: clash.id, comment: 'Test' }, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('resolution_type')
    end

    it 'validates resolution_type values' do
      post :resolve, params: {
        id: clash.id,
        resolution_type: 'invalid_type',
        comment: 'Test'
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error if clash already resolved' do
      clash.update!(status: :resolved, resolution_type: :redesign)

      post :resolve, params: {
        id: clash.id,
        resolution_type: 'relocated',
        comment: 'Test'
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
