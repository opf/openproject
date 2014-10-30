require 'spec_helper'
require 'rack/test'

describe 'API v3 Root resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: []) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }

  describe '#get' do
    subject(:response) { last_response }
    let(:get_path) { "/api/v3" }

    context 'anonymous user' do
      before do
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with links' do
        expect(subject.body).to have_json_path('_links/priorities')
        expect(subject.body).to have_json_path('_links/project')
        expect(subject.body).to have_json_path('_links/statuses')
      end
    end

    context 'logged in user' do
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

      it 'should respond with links' do
        expect(subject.body).to have_json_path('_links/priorities')
        expect(subject.body).to have_json_path('_links/project')
        expect(subject.body).to have_json_path('_links/statuses')
      end
    end
  end
end
