# frozen_string_literal: true

RSpec.describe API::V3::Cde::ContainersController, type: :controller do
  render_views

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    # Grant user permission to view and edit containers
    add_permission(project, user, :view_wip_container)
    add_permission(project, user, :edit_container)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { project_id: project.identifier, api: true }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    let(:container) { create(:cde_container, project: project, owner: user) }

    it 'returns http success' do
      get :show, params: { project_id: project.identifier, id: container.id, api: true }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        container: {
          identifier: 'PRJ-BIM-Z1-L2-DR-A-0001',
          title: 'Test Container',
          description: 'Test Description'
        }
      }
    end

    it 'creates a new container' do
      expect {
        post :create, params: { project_id: project.identifier, **valid_attributes, api: true }
      }.to change(Cde::Container, :count).by(1)
    end

    it 'returns created status' do
      post :create, params: { project_id: project.identifier, **valid_attributes, api: true }
      expect(response).to have_http_status(:created)
    end

    it 'creates initial working revision' do
      post :create, params: { project_id: project.identifier, **valid_attributes, api: true }
      container = Cde::Container.last
      expect(container.revisions.count).to eq(1)
      expect(container.working_revision.is_working).to be true
    end

    it 'emits audit event' do
      expect {
        post :create, params: { project_id: project.identifier, **valid_attributes, api: true }
      }.to change(Cde::AuditEvent, :count).by(1)
    end
  end
end
