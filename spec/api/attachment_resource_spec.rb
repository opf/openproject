require 'spec_helper'
require 'rack/test'

describe 'API v3 Attachment resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user, project: project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:attachment) { FactoryGirl.create(:attachment, container: work_package) }
  let(:model) { ::API::V3::Attachments::AttachmentModel.new(attachment) }
  let(:representer) { ::API::V3::Attachments::AttachmentRepresenter.new(model) }

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { "/api/v3/attachments/#{attachment.id}" }
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct attachment' do
        expect(subject.body).to be_json_eql(representer.to_json)
      end

      context 'requesting nonexistent attachment' do
        let(:get_path) { "/api/v3/attachments/9999" }
        it 'should respond with 404' do
          expect(subject.status).to eq(404)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_found'.to_json).at_path('title')
        end
      end

      context 'requesting attachments without sufficient permissions' do
        let(:another_project) { FactoryGirl.create(:project, is_public: false) }
        let(:another_work_package) { FactoryGirl.create(:work_package, project: another_project) }
        let(:another_attachment) { FactoryGirl.create(:attachment, container: another_work_package) }
        let(:get_path) { "/api/v3/attachments/#{another_attachment.id}" }

        it 'should respond with 403' do
          expect(subject.status).to eq(403)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authorized'.to_json).at_path('title')
        end
      end
    end

    context 'anonymous user' do
      let(:get_path) { "/api/v3/attachments/#{attachment.id}" }
      let(:project) { FactoryGirl.create(:project, is_public: true) }
      after { Setting.delete_all }

      context 'when access for anonymous user is allowed' do
        before do
          Setting.login_required = 0
          get get_path
        end

        it 'should respond with 200' do
          expect(subject.status).to eq(200)
        end

        it 'should respond with correct activity' do
          expect(subject.body).to be_json_eql(representer.to_json)
        end
      end

      context 'when access for anonymous user is not allowed' do
        before do
          Setting.login_required = 1
          get get_path
        end

        it 'should respond with 401' do
          expect(subject.status).to eq(401)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authenticated'.to_json).at_path('title')
        end
      end
    end
  end
end
