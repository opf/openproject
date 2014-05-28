require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource' do
  include Rack::Test::Methods

  let(:path) { "/api/v3/work_packages/#{work_package.id}" }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user) }
  let(:type) { FactoryGirl.create(:type_bug) }
  let(:status) {FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version) }
  let(:user) { FactoryGirl.create(:user) }

  describe '#patch' do

    let(:valid_request) do
      {
        subject: 'Updated subject',
        type: type.name,
        description: 'Updated description',
        status: status.name,
        priority: priority.name,
        startDate: Date.today - 1.week,
        dueDate: Date.today,
        estimatedTime: { units: 'hours', value: 12.0 }.to_json,
        percentageDone: 20,
        versionId: version.id,
        projectId: project.id,
        responsibleId: user.id,
        assigneeId: user.id
      }
    end

    let(:expected_response) do
      {
        "_type" => 'WorkPackage',
        "_links" => {
          "self" => {
            "href" => "http://localhost:3000/api/v3/work_packages/#{work_package.id}",
            "title" => valid_request[:subject]
          }
        },
        "id" => work_package.id,
        "subject" => valid_request[:subject],
        "type" => valid_request[:type],
        "description" => valid_request[:description],
        "status" => valid_request[:status],
        "priority" => valid_request[:priority],
        "startDate" => valid_request[:startDate].to_s,
        "dueDate" => valid_request[:dueDate].to_s,
        "estimatedTime" => JSON.parse(valid_request[:estimatedTime]),
        "percentageDone" => valid_request[:percentageDone],
        "versionId" => version.id,
        "versionName" => version.name,
        "projectId" => valid_request[:projectId],
        "projectName" => project.name,
        "responsibleId" => valid_request[:responsibleId],
        "responsibleName" => user.name,
        "responsibleLogin" => user.login,
        "responsibleMail" => user.mail,
        "assigneeId" => valid_request[:assigneeId],
        "assigneeName" => user.name,
        "assigneeLogin" => user.login,
        "assigneeMail" => user.mail,
        "authorName" => work_package.author.name,
        "authorLogin" => work_package.author.login,
        "authorMail" => work_package.author.mail,
        "createdAt" => work_package.created_at.utc.iso8601,
        "updatedAt" => work_package.updated_at.utc.iso8601
      }
    end

    context 'when logged in as a project member' do

      before(:each) { User.stub(:current).and_return(current_user) }

      context 'valid request' do

        before(:each) { patch path, valid_request }

        it 'should respond with 200' do
          last_response.status.should eq(200)
        end

        it 'should respond with updated work package' do
          parsed_response = JSON.parse(last_response.body)
          parsed_response.should eq(expected_response)
        end

      end
    end
  end
end



#       it 'should respond with updated work package' do
#         properties = {
#           subject: 'Updated subject',
#           type:
#         }
#         patch path
#       end

#       it 'should contain corret "_type"' do
#         patch path
#         parsed_response = JSON.parse(last_response.body)
#         parsed_response['_type'].should eq('WorkPackage')
#       end

#       it 'should contain correct "_links"' do
#         patch path
#         parsed_response = JSON.parse(last_response.body)
#         links = { self: { href: "http://localhost:3000#{path}", title: work_package.subject }}.as_json
#         parsed_response['_links'].should eq(links)
#       end



#       it 'should allow to update work package\`s properties' do
#         properties = {
#           type: bug,
#           status: status,
#           priority: priority,
#           subject: 'Updated subject',
#           description: 'Updated description'
#         }

#         patch path, properties

#         parsed_response = JSON.parse(last_response.body)

#         parsed_response['type'].should eq(properties[:type].name)
#         parsed_response['status'].should eq(properties[:status].name)
#         parsed_response['priority'].should eq(properties[:priority].name)
#         parsed_response['subject'].should eq(properties[:subject])
#         parsed_response['description'].should eq(properties[:description])
#       end

#       it 'should allow to change due and start date' do
#         start_date = Time.now
#         due_date = start_date - 1.week

#         properties = {
#           startDate: Time.now - 1.week,
#           dueDate: Time.now
#         }

#         patch path, properties

#         parsed_response = JSON.parse(last_response.body)

#         parsed_response['start_date'].should eq(properties[:start_date])
#         parsed_response['due_date'].should eq(properties[:due_date])
#       end

#       let(:project) { FactoryGirl.create(:project) }

#       it 'should allow to change a project' do
#         patch path, { projectId: project.id }

#         parsed_response = JSON.parse(last_response.body)

#         parsed_response['projectId'].should eq(project.id)
#         parsed_response['projectName'].should eq(project.name)
#       end

#       let(:user) { FactoryGirl.create(:user) }

#       it 'should allow to change a responsible user' do
#         patch path, { responsibleId: user.id }

#         parsed_response = JSON.parse(last_response.body)

#         parsed_response['responsibleId'].should eq(user.id)
#         parsed_response['responsibleName'].should eq(user.name)
#         parsed_response['responsibleMail'].should eq(user.mail)
#         parsed_response['responsibleLogin'].should eq(user.login)
#       end

#       it 'should allow to change an assignee' do
#         patch path, { assigneeId: user.id }

#         parsed_response = JSON.parse(last_response.body)

#         parsed_response['assigneeId'].should eq(user.id)
#         parsed_response['assigneeName'].should eq(user.name)
#         parsed_response['assigneeMail'].should eq(user.mail)
#         parsed_response['assigneeLogin'].should eq(user.login)
#       end
#     end

#     context 'when acting like an anonymous user' do

#     end
#   end
# end
