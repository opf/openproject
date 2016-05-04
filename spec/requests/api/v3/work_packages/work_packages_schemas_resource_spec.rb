#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::Schema::WorkPackageSchemasAPI, type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project) }
  let(:type) { FactoryGirl.create(:type) }
  let(:current_user) { FactoryGirl.build(:user, member_in_project: project) }

  describe 'GET /api/v3/work_packages/schemas/:id' do
    let(:schema_path) { api_v3_paths.work_package_schema project.id, type.id }

    def cache_key
      # Compare with ETag composed of project and customizations
      # to avoid evaluating the server request
      custom_fields = project.all_work_package_custom_fields

      custom_fields_key = ActiveSupport::Cache.expand_cache_key custom_fields

      ["api/v3/work_packages/schema/#{project.id}-#{type.id}",
       type.updated_at,
       Digest::SHA2.hexdigest(custom_fields_key)]
    end

    context 'logged in' do
      before do
        allow(User).to receive(:current).and_return(current_user)
        get schema_path
      end

      context 'valid schema' do
        it 'should return HTTP 200' do
          expect(last_response.status).to eql(200)
        end

        it 'should set a weak ETag' do
          expect(last_response.headers['ETag']).to match(/W\/\"\w+\"/)
        end

        it 'caches the response' do
          schema_class = API::V3::WorkPackages::Schema::TypedWorkPackageSchema
          representer_class = API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter

          schema = schema_class.new(project: project,
                                    type: type)
          self_link = api_v3_paths.work_package_schema(project.id, type.id)
          represented_schema = representer_class.create(schema,
                                                        self_link: self_link,
                                                        current_user: nil)

          expect(Rails.cache.fetch(represented_schema.cache_key)).to_not be_nil
        end
      end

      context 'id is too long' do
        it_behaves_like 'not found' do
          let(:schema_path) { "#{api_v3_paths.work_package_schema project.id, type.id}-1" }
        end
      end

      context 'id is too short' do
        it_behaves_like 'not found' do
          let(:schema_path) { "/api/v3/work_packages/schemas/#{project.id}" }
        end
      end

      context 'id is missing' do
        it_behaves_like 'not found' do
          let(:schema_path) { '/api/v3/work_packages/schemas/' }
        end
      end
    end

    context 'not logged in' do
      it 'should act as if the schema does not exist' do
        get schema_path
        expect(last_response.status).to eql(404)
      end
    end
  end

  describe 'GET /api/v3/work_packages/schemas/sums' do
    let(:schema_path) { api_v3_paths.work_package_sums_schema }
    subject { last_response }

    before do
      allow(Setting)
        .to receive(:work_package_list_summable_columns)
        .and_return(['estimated_hours'])
    end

    context 'logged in' do
      before do
        allow(User).to receive(:current).and_return(current_user)
        get schema_path
      end

      context 'valid schema' do
        it 'should return HTTP 200' do
          expect(last_response.status).to eql(200)
        end

        # Further fields are tested in the representer specs
        it 'should return the schema for estimated_hours' do
          expected = { 'type': 'Duration',
                       'name': 'Estimated time',
                       'visibility': 'default',
                       'required': false,
                       'hasDefault': false,
                       'writable': false }
          expect(subject.body).to be_json_eql(expected.to_json).at_path('estimatedTime')
        end
      end
    end

    context 'not logged in' do
      it 'should act as if the schema does not exist' do
        get schema_path
        expect(last_response.status).to eql(404)
      end
    end
  end
end
