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

  describe '#get' do
    let(:get_path) { "/api/v3/queries/#{private_query.id}" }
    let(:expected_response) do
      {
        "_type" => 'Query',
        "_links" => {
          "self" => {
            "href" => "http://localhost:3000/api/v3/queries/#{private_query.id}",
            "title" => private_query.name
          }
        },
        "id" => private_query.id,
        "name" => private_query.name,
        "projectId" => private_query.project_id,
        "projectName" => private_query.project.name,
        "userId" => private_query.user_id,
        "userName" => private_query.user.try(:name),
        "userLogin" => private_query.user.try(:login),
        "userMail" => private_query.user.try(:mail),
        "filters" => private_query.filters,
        "isPublic" => private_query.is_public.to_s,
        "columnNames" => private_query.column_names,
        "sortCriteria" => private_query.sort_criteria,
        "groupBy" => private_query.group_by,
        "displaySums" => private_query.display_sums.to_s
      }
    end

    context 'accessing private queries' do
      context 'when acting as a user with permission to view query' do
        before(:each) do
          allow(User).to receive(:current).and_return current_user
          member = FactoryGirl.build(:member, user: current_user, project: work_package.project)
          member.role_ids = [role.id]
          member.save!
          get get_path
        end

        it 'should respond with 200' do
          last_response.status.should eq(200)
        end

        it 'should respond with work package in HAL+JSON format' do
          parsed_response = JSON.parse(last_response.body)
          parsed_response.should eq(expected_response)
        end
      end
    end

  end

  describe '#star' do

  end
end
