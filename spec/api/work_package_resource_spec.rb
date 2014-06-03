require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource' do
  include Rack::Test::Methods

  let(:path) { "/api/v3/work_packages/#{work_package.id}" }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user) }
  let(:type) { FactoryGirl.create(:type_bug) }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version) }
  let(:user) { FactoryGirl.create(:user) }

  describe '#patch' do

    let(:valid_request) do
      {
        subject: 'Updated subject',
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
        "type" => work_package.type.name,
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

      context 'trying to set properties' do
        context '#subject' do
          let(:border_length_subject) { subject = ''; 255.times { subject << 'c' }; subject; }

          it 'should allow subject 255 chars long' do
            patch path, valid_request.tap{ valid_request['subject'] = border_length_subject }
            parsed_response = JSON.parse(last_response.body)
            parsed_response['subject'].should eq(border_length_subject)
          end

          context 'if blank' do
            before(:each) { patch path, valid_request.tap{ valid_request['subject'] = '' }}

            it 'should respond with 422' do
              last_response.status.should eq(422)
            end

            it 'should respond with explanatory error message' do
              parsed_errors = JSON.parse(last_response.body)['errors']
              parsed_errors.should eq([{ 'key' => 'subject', 'messages' => ['can\'t be blank']}])
            end
          end

          context 'if longer than 255 characters' do
            let(:too_long_subject) { border_length_subject + 'c' }
            before(:each) { patch path, valid_request.tap{ valid_request['subject'] = too_long_subject }}

            it 'should respond with 422' do
              last_response.status.should eq(422)
            end

            it 'should respond with explanatory error message' do
              parsed_errors = JSON.parse(last_response.body)['errors']
              parsed_errors.should eq([{ 'key' => 'subject', 'messages' => ['is too long (maximum is 255 characters)']}])
            end
          end
        end

        context '#type' do
          before(:each) { patch path, valid_request.tap{ valid_request['type'] = 'any-type' }}

          it 'should respond with 422' do
            last_response.status.should eq(422)
          end

          it 'should respond with explanatory error message' do
            parsed_errors = JSON.parse(last_response.body)['errors']
            parsed_errors.should eq([{ 'key' => 'type', 'messages' => ['is read-only']}])
          end
        end

        context '#status' do
          context 'if blank' do
            before(:each) { patch path, valid_request.tap{ valid_request['status'] = '' }}

            it 'should respond with 422' do
              last_response.status.should eq(422)
            end

            it 'should respond with explanatory error message' do
              parsed_errors = JSON.parse(last_response.body)['errors']
              parsed_errors.should eq([{ 'key' => 'status', 'messages' => ['can\'t be blank']}])
            end
          end

          context 'if current user is not allowed to set the status' do
            let(:not_allowed_status) { FactoryGirl.create(:status, name: 'Not allowed') }
            before(:each) { patch path, valid_request.tap{ valid_request['status'] = not_allowed_status.name }}

            it 'should respond with 422' do
              # last_response.status.should eq(422)
              # TODO: needs discussion (will probably use work_package.new_statuses_allowed_to(current_user))
            end

            it 'should respond with explanatory error message' do
              # TODO: needs discussion (will probably use work_package.new_statuses_allowed_to(current_user))
            end
          end
        end

        context '#priority' do

          it 'should allow to unset the priority' do
            patch path, valid_request.tap{ valid_request['priority'] = nil }
            parsed_response = JSON.parse(last_response.body)
            parsed_response.keys.include?('priority').should eq(true)
            parsed_response['priority'].should be_blank
          end

          context 'if priority isn\'t in the system' do

            it 'should respond with 422' do
              # TODO: needs discussion (how to get available priorities for a work package)
            end

            it 'should respond with explanatory error message' do
              # TODO
            end
          end
        end

      end
    end
  end
end
