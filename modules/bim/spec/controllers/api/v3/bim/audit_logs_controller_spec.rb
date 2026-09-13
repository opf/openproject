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

RSpec.describe Api::V3::Bim::AuditLogsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:user_with_permission) { create(:user, global_permissions: [:manage_ifc_models]) }
  let(:regular_user) { create(:user) }
  let(:project) { create(:project) }

  before do
    # Create audit logs
    create_list(:bim_audit_log, 5, :model_upload, project: project)
    create_list(:bim_audit_log, 3, :clash_detection_run, project: project)
    create(:bim_audit_log, :permission_changed, project: project)
  end

  describe 'GET #index' do
    context 'when user is admin' do
      before { login_as(admin) }

      it 'returns all audit logs for the project' do
        get :index, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['logs'].size).to eq(9)
      end

      it 'filters by action_type' do
        get :index, params: { project_id: project.id, action_type: 'model_upload' }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['logs'].size).to eq(5)
      end

      it 'filters by user_id' do
        user = create(:user)
        create(:bim_audit_log, user: user, project: project)

        get :index, params: { project_id: project.id, user_id: user.id }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['logs'].size).to eq(1)
        expect(json['logs'].first['user']['id']).to eq(user.id)
      end

      it 'filters by time period (since)' do
        old_log = create(:bim_audit_log, :old, project: project)

        get :index, params: { project_id: project.id, since: 1.week.ago.iso8601 }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['logs'].map { |l| l['id'] }).not_to include(old_log.id)
      end

      it 'paginates results' do
        get :index, params: { project_id: project.id, page: 1, per_page: 5 }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['logs'].size).to eq(5)
        expect(json['total']).to eq(9)
        expect(json['page']).to eq(1)
      end

      it 'orders by created_at descending' do
        get :index, params: { project_id: project.id }, format: :json

        json = JSON.parse(response.body)
        timestamps = json['logs'].map { |l| Time.parse(l['created_at']) }

        expect(timestamps).to eq(timestamps.sort.reverse)
      end
    end

    context 'when user has manage_ifc_models permission' do
      before { login_as(user_with_permission) }

      it 'returns audit logs' do
        get :index, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user lacks permission' do
      before { login_as(regular_user) }

      it 'returns forbidden' do
        get :index, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not logged in' do
      it 'returns unauthorized' do
        get :index, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #export' do
    context 'when user is admin' do
      before { login_as(admin) }

      it 'exports audit logs as CSV' do
        get :export, params: { project_id: project.id }, format: :csv

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include("audit_logs_#{project.identifier}")
      end

      it 'includes CSV headers' do
        get :export, params: { project_id: project.id }, format: :csv

        expect(response.body).to include('ID,Timestamp,User,Project,Action,IP Address,Details')
      end

      it 'filters by time period' do
        old_log = create(:bim_audit_log, :old, project: project)

        get :export, params: { project_id: project.id, since: 1.week.ago.iso8601 }, format: :csv

        expect(response.body).not_to include(old_log.id.to_s)
      end
    end

    context 'when user lacks permission' do
      before { login_as(regular_user) }

      it 'returns forbidden' do
        get :export, params: { project_id: project.id }, format: :csv

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #report' do
    context 'when user is admin' do
      before { login_as(admin) }

      it 'generates security report' do
        get :report, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to include(
          'project_id',
          'project_name',
          'report_period',
          'activity_summary',
          'top_users',
          'security_sensitive_actions',
          'total_actions'
        )
      end

      it 'includes activity summary' do
        get :report, params: { project_id: project.id }, format: :json

        json = JSON.parse(response.body)
        expect(json['activity_summary']['model_upload']).to eq(5)
        expect(json['activity_summary']['clash_detection_run']).to eq(3)
      end

      it 'includes security sensitive actions' do
        get :report, params: { project_id: project.id }, format: :json

        json = JSON.parse(response.body)
        expect(json['security_sensitive_actions'].size).to be >= 1
      end

      it 'filters by time period' do
        get :report, params: { project_id: project.id, since: 1.week.ago.iso8601 }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['total_actions']).to eq(9)
      end
    end

    context 'when user lacks permission' do
      before { login_as(regular_user) }

      it 'returns forbidden' do
        get :report, params: { project_id: project.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
