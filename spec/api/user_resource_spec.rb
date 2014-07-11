require 'spec_helper'
require 'rack/test'

describe 'API v3 User resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:model) { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { ::API::V3::Users::UserRepresenter.new(model) }

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { "/api/v3/users/#{user.id}" }
      before do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct attachment' do
        expect(subject.body).to be_json_eql(representer.to_json)
      end

      context 'requesting nonexistent user' do
        let(:get_path) { "/api/v3/users/9999" }
        it 'should respond with 404' do
          expect(subject.status).to eq(404)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_found'.to_json).at_path('title')
        end
      end
    end

    context 'anonymous user' do
      let(:get_path) { "/api/v3/users/#{user.id}" }

      context 'when access for anonymous user is allowed' do
        before { get get_path }

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
        after { Setting.login_required = 0 }

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
