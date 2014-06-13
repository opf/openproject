require 'spec_helper'
require 'rack/test'

describe 'API v3 Query resource' do
  include Rack::Test::Methods

  let(:work_package) { FactoryGirl.create(:work_package, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:unauthorize_user) { FactoryGirl.create(:user) }
  let(:query) { FactoryGirl.create(:public_query) }
  let(:private_query) { FactoryGirl.create(:private_query, project: project) }

  describe '#star' do
    context 'anonymous user' do

    end

    context 'user with permissions for the project' do

    end

    context 'user without permissions for the project'
  end

  describe '#unstar' do

  end
end
