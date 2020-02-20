#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package form resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers

  let(:project) { FactoryBot.create(:project, public: false) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:authorized_user) { FactoryBot.create(:user, member_in_project: project) }
  let(:unauthorized_user) { FactoryBot.create(:user) }

  before do
    allow(Story).to receive(:types).and_return([work_package.type_id])
  end

  describe '#post' do
    shared_examples_for 'valid payload' do
      subject { response.body }

      it { expect(response.status).to eq(200) }

      it { is_expected.to have_json_path('_embedded/payload') }

      it { is_expected.to have_json_path('_embedded/payload/lockVersion') }

      it { is_expected.to have_json_path('_embedded/payload/subject') }

      it_behaves_like 'API V3 formattable', '_embedded/payload/description' do
        let(:format) { 'markdown' }
        let(:raw) { defined?(raw_value) ? raw_value : work_package.description.to_s }
        let(:html) {
          defined?(html_value) ? html_value : ('<p>' + work_package.description.to_s + '</p>')
        }
      end
    end

    shared_examples_for 'having no errors' do
      it {
        expect(subject.body).to be_json_eql({}.to_json).at_path('_embedded/validationErrors')
      }
    end

    shared_examples_for 'having an error' do |property|
      it { expect(subject.body).to have_json_path("_embedded/validationErrors/#{property}") }

      describe 'error body' do
        let(:error_path) { "_embedded/validationErrors/#{property}" }
        let(:error_id) { 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation'.to_json }

        let(:error_body) {
          parse_json(subject.body)['_embedded']['validationErrors'][property]
        }

        it { expect(subject.body).to have_json_path(error_path) }
        it {
          expect(subject.body).to be_json_eql(error_id).at_path("#{error_path}/errorIdentifier")
        }
      end
    end

    let(:post_path) { "/api/v3/work_packages/#{work_package.id}/form" }
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context 'post request' do
      before(:each) do
        allow(User).to receive(:current).and_return current_user
        post post_path, (params ? params.to_json : nil), 'CONTENT_TYPE' => 'application/json'
      end
    end

    let(:params) {}
    let(:current_user) { authorized_user }

    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    describe 'storyPoints' do
      include_context 'post request'

      context 'valid storyPoints' do
        let(:params) { valid_params.merge(storyPoints: 42) }

        it_behaves_like 'valid payload'

        it_behaves_like 'having no errors'

        it 'should respond with updated story points' do
          expect(subject.body).to be_json_eql(42.to_json).at_path('_embedded/payload/storyPoints')
        end
      end

      context 'invalid storyPoints' do
        let(:params) { valid_params.merge(storyPoints: 'two') }

        it_behaves_like 'valid payload'

        it_behaves_like 'having an error', 'storyPoints'
      end
    end

    describe 'remainingTime' do
      include_context 'post request'

      context 'valid remainingTime' do
        let(:params) { valid_params.merge(remainingTime: 'PT2H45M') }

        it_behaves_like 'valid payload'

        it_behaves_like 'having no errors'

        it 'should respond with updated story points' do
          expect(subject.body).to be_json_eql('PT2H45M'.to_json)
            .at_path('_embedded/payload/remainingTime')
        end
      end

      context 'invalid remainingTime' do
        let(:params) { valid_params.merge(remainingTime: 3) }

        it_behaves_like 'format error',
                        I18n.t('api_v3.errors.invalid_format',
                               property: 'remainingTime',
                               expected_format: 'ISO 8601 duration',
                               actual: '3')
      end
    end
  end
end
