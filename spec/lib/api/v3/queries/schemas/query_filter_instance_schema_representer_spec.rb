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

describe ::API::V3::Queries::Schemas::QueryFilterInstanceSchemaRepresenter, clear_cache: true do
  include ::API::V3::Utilities::PathHelper

  let(:filter) { Queries::WorkPackages::Filter::StatusFilter.create! }
  let(:assigned_to_filter) { Queries::WorkPackages::Filter::AssignedToFilter.create! }
  let(:custom_field_filter) do
    filter = Queries::WorkPackages::Filter::CustomFieldFilter.from_custom_field! custom_field: custom_field

    allow(WorkPackageCustomField)
      .to receive(:find_by)
      .with(id: custom_field.id)
      .and_return(custom_field)

    filter
  end
  let(:custom_field) { FactoryBot.build_stubbed(:list_wp_custom_field) }
  let(:instance) do
    described_class.new(filter,
                        self_link,
                        current_user: user,
                        form_embedded: form_embedded)
  end
  let(:form_embedded) { false }
  let(:self_link) { 'bogus_self_path' }
  let(:project) { nil }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:json_cacheable) { true }
  let(:json_cache_key) { 'some key' }
  let(:dependency) do
    double('dependency',
           to_hash: { 'lorem': 'ipsum' },
           json_cacheable?: json_cacheable,
           json_cache_key: json_cache_key)
  end

  context 'generation' do
    before do
      filter.available_operators.each do |operator|
        allow(::API::V3::Queries::Schemas::FilterDependencyRepresenterFactory)
          .to receive(:create)
          .with(filter,
                operator,
                form_embedded: form_embedded)
          .and_return(dependency)
      end
    end

    subject(:generated) { instance.to_json }

    context '_links' do
      describe 'self' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'self' }
          let(:href) { self_link }
        end
      end
    end

    context 'properties' do
      describe '_type' do
        it 'QueryFilterInstanceSchema' do
          expect(subject)
            .to be_json_eql('QueryFilterInstanceSchema'.to_json)
            .at_path('_type')
        end
      end

      describe 'name' do
        let(:path) { 'name' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'String' }
          let(:name) { 'Name' }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { true }
        end
      end

      describe 'filter' do
        let(:path) { 'filter' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'QueryFilter' }
          let(:name) { Query.human_attribute_name('filter') }
          let(:required) { true }
          let(:writable) { true }
        end

        it_behaves_like 'does not link to allowed values'

        context 'when embedding' do
          let(:form_embedded) { true }

          it_behaves_like 'links to and embeds allowed values directly' do
            let(:hrefs) { [api_v3_paths.query_filter('status')] }
          end

          context 'with a custom field filter' do
            let(:filter) { custom_field_filter }

            it_behaves_like 'links to and embeds allowed values directly' do
              let(:hrefs) { [api_v3_paths.query_filter("customField#{custom_field.id}")] }
            end
          end
        end
      end

      describe 'operator' do
        let(:path) { 'operator' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'QueryOperator' }
          let(:name) { Query.human_attribute_name('operator') }
          let(:required) { true }
          let(:writable) { true }
        end

        it_behaves_like 'does not link to allowed values'

        context 'when embedding' do
          let(:form_embedded) { true }

          it_behaves_like 'links to and embeds allowed values directly' do
            let(:hrefs) do
              [api_v3_paths.query_operator(CGI.escape('o')),
               api_v3_paths.query_operator(CGI.escape('=')),
               api_v3_paths.query_operator(CGI.escape('c')),
               api_v3_paths.query_operator(CGI.escape('!')),
               api_v3_paths.query_operator(CGI.escape('*'))]
            end
          end
        end
      end

      describe '_dependencies/0 (we only have one)' do
        describe '_type' do
          it 'is SchemaDependency' do
            expect(subject)
              .to be_json_eql('SchemaDependency'.to_json)
              .at_path('_dependencies/0/_type')
          end
        end

        describe 'on' do
          it 'is "operator"' do
            expect(subject)
              .to be_json_eql('operator'.to_json)
              .at_path('_dependencies/0/on')
          end
        end

        describe 'dependencies' do
          it 'is the hash' do
            expected = {
              api_v3_paths.query_operator(CGI.escape('=')) => { "lorem": "ipsum" },
              api_v3_paths.query_operator(CGI.escape('c')) => { "lorem": "ipsum" },
              api_v3_paths.query_operator(CGI.escape('!')) => { "lorem": "ipsum" },
              api_v3_paths.query_operator(CGI.escape('*')) => { "lorem": "ipsum" },
              api_v3_paths.query_operator(CGI.escape('o')) => { "lorem": "ipsum" }
            }

            expect(subject)
              .to be_json_eql(expected.to_json)
              .at_path('_dependencies/0/dependencies')
          end

          context 'when filter is a list filter' do
            let(:filter) { Queries::WorkPackages::Filter::AuthorFilter.create! }

            it 'is the hash' do
              expected = {
                api_v3_paths.query_operator(CGI.escape('=')) => { "lorem": "ipsum" },
                api_v3_paths.query_operator(CGI.escape('!')) => { "lorem": "ipsum" }
              }

              expect(subject)
                .to be_json_eql(expected.to_json)
                .at_path('_dependencies/0/dependencies')
            end
          end
        end
      end
    end
  end

  describe 'caching' do
    before do
      filter.available_operators.each do |operator|
        allow(::API::V3::Queries::Schemas::FilterDependencyRepresenterFactory)
          .to receive(:create)
          .with(filter,
                operator,
                form_embedded: form_embedded)
          .and_return(dependency)
      end
    end

    before do
      # fill the cache
      instance.to_json
    end

    it 'is cached' do
      expect(instance)
        .not_to receive(:to_hash)

      instance.to_json
    end

    context 'with an uncacheable dependency' do
      let(:json_cacheable) { false }

      it 'is not cached' do
        expect(instance)
          .to receive(:to_hash)

        instance.to_json
      end
    end

    it 'busts the cache on the form_embedded attribute' do
      instance.form_embedded = !form_embedded

      expect(instance)
        .to receive(:to_hash)

      instance.to_json
    end

    it 'busts the cache on a different cache key from a dependency' do
      allow(dependency)
        .to receive(:json_cache_key)
        .and_return(['and', 'now', 'to', 'something', 'completely', 'different'])

      expect(instance)
        .to receive(:to_hash)

      instance.to_json
    end

    it 'busts the cache on changes to the locale' do
      expect(instance)
        .to receive(:to_hash)

      I18n.with_locale(:de) do
        instance.to_json
      end
    end
  end
end
