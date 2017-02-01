#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::Schemas::QuerySchemaRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:query) { Query.new }

  let(:instance) { described_class.new(query, form_embedded: form_embedded, self_link: self_link) }
  let(:form_embedded) { false }
  let(:self_link) { 'bogus_self_path' }

  subject(:generated) { instance.to_json }

  context 'generation' do
    context '_links' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'self' }
        let(:href) { self_link }
      end
    end

    context 'attributes' do
      describe '_type' do
        it 'is Schema' do
          expect(subject)
            .to be_json_eql('Schema'.to_json)
            .at_path('_type')
        end
      end

      describe 'id' do
        let(:path) { 'id' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Integer' }
          let(:name) { Query.human_attribute_name('id') }
          let(:required) { true }
          let(:writable) { false }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'name' do
        let(:path) { 'name' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'String' }
          let(:name) { Query.human_attribute_name('name') }
          let(:required) { true }
          let(:writable) { true }
        end

        it_behaves_like 'indicates length requirements' do
          let(:min_length) { 1 }
          let(:max_length) { 255 }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'user' do
        let(:path) { 'user' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'User' }
          let(:name) { Query.human_attribute_name('user') }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'project' do
        let(:path) { 'project' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Project' }
          let(:name) { Query.human_attribute_name('project') }
          let(:required) { false }
          let(:writable) { true }
        end

        it_behaves_like 'has no visibility property'

        it_behaves_like 'does not link to allowed values'

        context 'when embedding' do
          let(:form_embedded) { true }

          it_behaves_like 'links to allowed values via collection link' do
            let(:href) { api_v3_paths.available_query_projects }
          end
        end
      end

      describe 'public' do
        let(:path) { 'public' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Boolean' }
          let(:name) { Query.human_attribute_name('public') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'sums' do
        let(:path) { 'sums' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Boolean' }
          let(:name) { Query.human_attribute_name('sums') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'starred' do
        let(:path) { 'starred' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Boolean' }
          let(:name) { Query.human_attribute_name('starred') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'columns' do
        let(:path) { 'columns' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { '[]QueryColumn' }
          let(:name) { Query.human_attribute_name('columns') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'filters' do
        let(:path) { 'filters' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { '[]QueryFilterInstance' }
          let(:name) { Query.human_attribute_name('filters') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'groupBy' do
        let(:path) { 'groupBy' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { '[]QueryGroupBy' }
          let(:name) { Query.human_attribute_name('group_by') }
          let(:required) { false }
          let(:writable) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'sortBy' do
        let(:path) { 'sortBy' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { '[]QuerySortBy' }
          let(:name) { Query.human_attribute_name('sort_by') }
          let(:required) { false }
          let(:writable) { true }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'results' do
        let(:path) { 'results' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'WorkPackageCollection' }
          let(:name) { Query.human_attribute_name('results') }
          let(:required) { false }
          let(:writable) { false }
        end

        it_behaves_like 'has no visibility property'
      end
    end
  end
end
