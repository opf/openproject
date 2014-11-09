require 'spec_helper'
require 'rack/test'

describe 'API v3 Render resource' do
  include Rack::Test::Methods

  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:user) { FactoryGirl.create(:user, member_in_project: project) }

  describe '#post' do
    let(:path) { '/api/v3/render/textile' }

    subject(:response) { last_response }

    before(:each) do
      allow(User).to receive(:current).and_return(user)
      post post_path, params, 'CONTENT_TYPE' => 'text/plain'
    end

    describe 'response' do
      shared_examples_for 'valid response' do
        it { expect(subject.status).to eq(200) }

        it { expect(subject.content_type).to eq('text/html') }

        it { expect(subject.body).to eq(textile) }
      end

      describe 'valid' do
        context 'w/o context' do
          let(:post_path) { path }
          let(:params) { 'Hello World! This *is* textile with a "link":http://community.openproject.org.' }
          let(:textile) { '<p>Hello World! This <strong>is</strong> textile with a <a href="http://community.openproject.org" class="external">link</a>.</p>' }

          it_behaves_like 'valid response'
        end

        context 'with context' do
          let(:post_path) { "#{path}?context=/api/v3/work_packages/#{work_package.id}" }
          let(:params) { "Hello World! Have a look at ##{work_package.id}" }
          let(:id) { work_package.id }
          let(:href) { "/work_packages/#{id}" }
          let(:title) { "#{work_package.subject} (#{work_package.status})" }
          let(:textile) { "<p>Hello World! Have a look at <a class=\"issue work_package status-1 priority-1\" href=\"#{href}\" title=\"#{title}\">##{id}</a></p>" }

          it_behaves_like 'valid response'
        end
      end

      describe 'invalid' do
        context 'with context' do
          let(:params) { '' }

          describe 'work package does not exist' do
            let(:post_path) { "#{path}?context=/api/v3/work_packages/-1" }

            it_behaves_like 'invalid render context', 'Context does not exist!'
          end

          describe 'work package not visible' do
            let(:invisible_work_package) { FactoryGirl.create(:work_package) }
            let(:post_path) { "#{path}?context=/api/v3/work_packages/#{invisible_work_package.id}" }

            it_behaves_like 'invalid render context', 'Context does not exist!'
          end

          describe 'context does not exist' do
            let(:post_path) { "#{path}?context=/api/v3/" }

            it_behaves_like 'invalid render context', 'No context found.'
          end

          describe 'unsupported context found' do
            let(:post_path) { "#{path}?context=/api/v3/activities/2" }

            it_behaves_like 'invalid render context', 'Unsupported context found.'
          end
        end

      end
    end
  end
end
