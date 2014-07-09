require 'spec_helper'
require 'rack/test'

RSpec.shared_examples 'API show endpoint' do |resource, authorized_user, path|
  include Rack::Test::Methods

  before { get(path) }
  subject(:response) { last_response }

  context 'logged in user' do
    before { allow(User).to receive(:current).and_return authorized_user }

    context 'with permission' do
      it 'should respond with 200' do
        binding.pry
        expect(subject.status).to eq(200)
      end
    end

    context 'without permission' do

    end
  end

  context 'anonymous user' do
    context 'when access for anonymous user is allowed' do

    end

    context 'when access for anonymous user is not allowed' do

    end
  end
end

describe 'API v3 Activity resource' do
  binding.pry
  user = FactoryGirl.create(:user)
  project = FactoryGirl.create(:project, is_public: true)
  work_package = FactoryGirl.create(:work_package, author: user, project: project)
  role = FactoryGirl.create(:role, permissions: [:view_work_packages])
  attachment = FactoryGirl.create(:attachment, container: work_package, author: user)
  model = ::API::V3::Attachments::AttachmentModel.new(attachment)
  representer = ::API::V3::Attachments::AttachmentRepresenter.new(model)
  path = "/api/v3/attachments/#{attachment.id}"
  member = FactoryGirl.build(:member, user: user, project: attachment.container.project)
  member.role_ids = [role.id]
  member.save!

  it_should_behave_like 'API show endpoint', representer, user, path
end
