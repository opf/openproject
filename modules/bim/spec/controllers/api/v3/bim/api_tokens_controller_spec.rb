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

RSpec.describe Api::V3::Bim::ApiTokensController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project) }

  before do
    login_as(user)
  end

  describe 'GET #index' do
    let!(:user_token1) { create(:bim_api_token, :read_only, user: user) }
    let!(:user_token2) { create(:bim_api_token, :write_access, user: user) }
    let!(:other_token) { create(:bim_api_token, user: other_user) }

    it 'returns only current user tokens' do
      get :index, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['tokens'].size).to eq(2)
      expect(json['tokens'].map { |t| t['id'] }).to contain_exactly(user_token1.id, user_token2.id)
    end

    it 'includes token details' do
      get :index, format: :json

      json = JSON.parse(response.body)
      token = json['tokens'].first

      expect(token).to include(
        'id',
        'name',
        'description',
        'token_prefix',
        'scopes',
        'active',
        'status',
        'created_at',
        'usage_count'
      )
    end

    it 'does not include token_hash' do
      get :index, format: :json

      json = JSON.parse(response.body)
      token = json['tokens'].first

      expect(token).not_to have_key('token_hash')
    end

    it 'filters by active status' do
      user_token1.revoke!

      get :index, params: { active: true }, format: :json

      json = JSON.parse(response.body)
      expect(json['tokens'].size).to eq(1)
      expect(json['tokens'].first['id']).to eq(user_token2.id)
    end
  end

  describe 'GET #show' do
    let!(:token) { create(:bim_api_token, :read_only, user: user) }

    it 'returns token details' do
      get :show, params: { id: token.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(token.id)
      expect(json['name']).to eq(token.name)
    end

    it 'does not return other users tokens' do
      other_token = create(:bim_api_token, user: other_user)

      get :show, params: { id: other_token.id }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for non-existent token' do
      get :show, params: { id: 99999 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'Revit Integration',
        description: 'Token for Revit plugin',
        scopes: ['read:models', 'write:models'],
        expires_in_days: 90
      }
    end

    it 'creates a new API token' do
      expect do
        post :create, params: valid_params, format: :json
      end.to change(Bim::ApiToken, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns the plain token only once' do
      post :create, params: valid_params, format: :json

      json = JSON.parse(response.body)
      expect(json['token']).to be_present
      expect(json['token'].length).to be > 20
      expect(json['message']).to include('Save this token')
    end

    it 'returns token details with the plain token' do
      post :create, params: valid_params, format: :json

      json = JSON.parse(response.body)
      expect(json['token_data']).to include(
        'id',
        'name',
        'description',
        'scopes',
        'expires_at'
      )
    end

    it 'associates token with current user' do
      post :create, params: valid_params, format: :json

      token = Bim::ApiToken.last
      expect(token.user).to eq(user)
    end

    it 'sets expiration when provided' do
      post :create, params: valid_params, format: :json

      token = Bim::ApiToken.last
      expect(token.expires_at).to be_within(1.hour).of(90.days.from_now)
    end

    it 'creates token without expiration when not provided' do
      post :create, params: valid_params.except(:expires_in_days), format: :json

      token = Bim::ApiToken.last
      expect(token.expires_at).to be_nil
    end

    it 'validates required fields' do
      post :create, params: { scopes: ['read:models'] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to include('name')
    end

    it 'validates scopes are valid' do
      post :create, params: valid_params.merge(scopes: ['invalid:scope']), format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to include('scopes')
    end

    it 'logs token creation in audit log' do
      expect do
        post :create, params: valid_params, format: :json
      end.to change(Bim::AuditLog, :count).by(1)

      log = Bim::AuditLog.last
      expect(log.action_type).to eq('api_token_created')
    end
  end

  describe 'PATCH #update' do
    let!(:token) { create(:bim_api_token, :read_only, user: user) }

    it 'updates token attributes' do
      patch :update, params: { id: token.id, name: 'Updated Name', description: 'New description' }, format: :json

      expect(response).to have_http_status(:ok)
      token.reload
      expect(token.name).to eq('Updated Name')
      expect(token.description).to eq('New description')
    end

    it 'updates scopes' do
      patch :update, params: { id: token.id, scopes: ['read:models', 'write:models', 'delete:models'] }, format: :json

      expect(response).to have_http_status(:ok)
      token.reload
      expect(token.scopes).to eq(['read:models', 'write:models', 'delete:models'])
    end

    it 'does not update other users tokens' do
      other_token = create(:bim_api_token, user: other_user)

      patch :update, params: { id: other_token.id, name: 'Hacked' }, format: :json

      expect(response).to have_http_status(:not_found)
      other_token.reload
      expect(other_token.name).not_to eq('Hacked')
    end

    it 'validates scopes' do
      patch :update, params: { id: token.id, scopes: ['invalid:scope'] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #revoke' do
    let!(:token) { create(:bim_api_token, :read_only, user: user, active: true) }

    it 'revokes the token' do
      post :revoke, params: { id: token.id }, format: :json

      expect(response).to have_http_status(:ok)
      token.reload
      expect(token.active).to be false
    end

    it 'returns revoked status' do
      post :revoke, params: { id: token.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['message']).to include('revoked')
      expect(json['token']['status']).to eq('revoked')
    end

    it 'does not revoke other users tokens' do
      other_token = create(:bim_api_token, user: other_user, active: true)

      post :revoke, params: { id: other_token.id }, format: :json

      expect(response).to have_http_status(:not_found)
      other_token.reload
      expect(other_token.active).to be true
    end

    it 'logs token revocation in audit log' do
      expect do
        post :revoke, params: { id: token.id }, format: :json
      end.to change(Bim::AuditLog, :count).by(1)

      log = Bim::AuditLog.last
      expect(log.action_type).to eq('api_token_revoked')
      expect(log.details['token_id']).to eq(token.id)
    end
  end

  describe 'DELETE #destroy' do
    let!(:token) { create(:bim_api_token, user: user) }

    it 'deletes the token' do
      expect do
        delete :destroy, params: { id: token.id }, format: :json
      end.to change(Bim::ApiToken, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns success message' do
      delete :destroy, params: { id: token.id }, format: :json

      json = JSON.parse(response.body)
      expect(json['message']).to include('deleted')
    end

    it 'does not delete other users tokens' do
      other_token = create(:bim_api_token, user: other_user)

      expect do
        delete :destroy, params: { id: other_token.id }, format: :json
      end.not_to change(Bim::ApiToken, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when user is not logged in' do
    before { logout }

    it 'returns unauthorized for index' do
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for create' do
      post :create, params: { name: 'Test' }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
