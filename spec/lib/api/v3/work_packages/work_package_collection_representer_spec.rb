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

describe ::API::V3::WorkPackages::WorkPackageCollectionRepresenter do
  include API::V3::Utilities::PathHelper

  let(:self_base_link) { '/api/v3/example' }
  let(:work_packages) { WorkPackage.all }
  let(:user) { FactoryBot.build_stubbed(:user) }

  let(:query) { {} }
  let(:groups) { nil }
  let(:total_sums) { nil }
  let(:project) { nil }

  let(:page_parameter) { nil }
  let(:page_size_parameter) { nil }
  let(:default_page_size) { 30 }
  let(:total) { 5 }
  let(:embed_schemas) { false }

  let(:representer) do
    described_class.new(
      work_packages,
      self_base_link,
      query: query,
      project: project,
      groups: groups,
      total_sums: total_sums,
      page: page_parameter,
      per_page: page_size_parameter,
      current_user: user,
      embed_schemas: embed_schemas
    )
  end

  before do
    allow(user)
      .to receive(:allowed_to?)
      .and_return(true)

    FactoryBot.create_list(:work_package, total)
  end

  context 'generation' do
    subject(:collection) { representer.to_json }
    let(:collection_inner_type) { 'WorkPackage' }

    context '_links' do
      context 'representations' do
        context 'when the user has the export_work_packages permission' do
          let(:query) { { foo: 'bar' } }

          it 'has a collection of export formats' do
            expected_query = query.merge(pageSize: 30, offset: 1)
            expected = JSON.parse([
              {
                href: work_packages_path({ format: 'pdf' }.merge(expected_query)),
                type: 'application/pdf',
                identifier: 'pdf',
                title: I18n.t('export.format.pdf')
              },
              {
                href: work_packages_path({ format: 'pdf', show_descriptions: true }.merge(expected_query)),
                identifier: 'pdf-with-descriptions',
                type: 'application/pdf',
                title: I18n.t('export.format.pdf_with_descriptions')
              },
              {
                href: work_packages_path({ format: 'csv' }.merge(expected_query)),
                type: 'text/csv',
                identifier: 'csv',
                title: I18n.t('export.format.csv')
              },
              {
                href: work_packages_path({ format: 'atom' }.merge(expected_query)),
                identifier: 'atom',
                type: 'application/atom+xml',
                title: I18n.t('export.format.atom')
              }
            ].to_json)

            actual = JSON.parse(subject).dig('_links', 'representations')

            # As plugins might extend the representation, we only
            # check for a subset
            expect(actual)
              .to include(*expected)
          end

          context 'with project scope' do
            let(:project) { FactoryBot.build_stubbed(:project) }

            it 'has a project scoped collection of export formats if inside a project' do
              expected_query = query.merge(pageSize: 30, offset: 1)
              expected = JSON.parse([
                {
                  href: project_work_packages_path(project, { format: 'pdf' }.merge(expected_query)),
                  type: 'application/pdf',
                  identifier: 'pdf',
                  title: I18n.t('export.format.pdf')
                },
                {
                  href: project_work_packages_path(project, { format: 'pdf', show_descriptions: true }.merge(expected_query)),
                  type: 'application/pdf',
                  identifier: 'pdf-with-descriptions',
                  title: I18n.t('export.format.pdf_with_descriptions')
                },
                {
                  href: project_work_packages_path(project, { format: 'csv' }.merge(expected_query)),
                  identifier: 'csv',
                  type: 'text/csv',
                  title: I18n.t('export.format.csv')
                },
                {
                  href: project_work_packages_path(project, { format: 'atom' }.merge(expected_query)),
                  identifier: 'atom',
                  type: 'application/atom+xml',
                  title: I18n.t('export.format.atom')
                }
              ].to_json)

              actual = JSON.parse(subject).dig('_links', 'representations')

              # As plugins might extend the representation, we only
              # check for a subset
              expect(actual)
                .to include(*expected)
            end
          end
        end

        context 'when the user lacks the export_work_packages permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:export_work_packages, project, global: project.nil?)
              .and_return(false)
          end

          it 'has no export links' do
            is_expected
              .to_not have_json_path('_links/representations')
          end
        end
      end
    end

    it 'does not render groups' do
      is_expected.not_to have_json_path('groups')
    end

    it 'does not render sums' do
      is_expected.not_to have_json_path('totalSums')
    end

    it 'has a schemas link' do
      ids = work_packages.map do |wp|
        [wp.project_id, wp.type_id]
      end

      path = api_v3_paths.work_package_schemas *ids

      is_expected
        .to be_json_eql(path.to_json)
        .at_path('_links/schemas/href')
    end

    describe 'ancestors' do
      before do
        expect(WorkPackage).to receive(:aggregate_ancestors).and_call_original
      end

      it 'are being eager loaded' do
        representer.represented.each do |wp|
          expect(wp.work_package_ancestors).to be_kind_of(Array)
          expect(wp.ancestors).to eq(wp.work_package_ancestors)
        end
      end
    end

    context 'when the user has the edit_work_package permission in any project' do
      before do
        allow(user)
          .to receive(:allowed_to?)
          .and_return(false)

        allow(user)
          .to receive(:allowed_to?)
          .with(:edit_work_packages, nil, global: true)
          .and_return(allowed)
      end

      context 'when allowed' do
        let(:allowed) { true }

        it 'has a link to templated edit work_package' do
          is_expected
            .to be_json_eql(api_v3_paths.work_package_form('{work_package_id}').to_json)
            .at_path('_links/editWorkPackage/href')
        end
      end

      context 'when allowed' do
        let(:allowed) { false }

        it 'has no link to templated edit work_package' do
          is_expected.not_to have_json_path('_links/editWorkPackage')
        end
      end
    end

    context 'when the user has the add_work_package permission in any project' do
      before do
        allow(user)
          .to receive(:allowed_to?)
          .and_return(false)

        allow(user)
          .to receive(:allowed_to?)
          .with(:add_work_packages, nil, global: true)
          .and_return(true)
      end

      it 'has a link to create work_packages' do
        is_expected
          .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
          .at_path('_links/createWorkPackage/href')
      end

      it 'declares to use POST to create work_packages' do
        is_expected
          .to be_json_eql(:post.to_json)
          .at_path('_links/createWorkPackage/method')
      end

      it 'has a link to create work_packages immediately' do
        is_expected
          .to be_json_eql(api_v3_paths.work_packages.to_json)
          .at_path('_links/createWorkPackageImmediate/href')
      end

      it 'declares to use POST to create work_packages immediately' do
        is_expected
          .to be_json_eql(:post.to_json)
          .at_path('_links/createWorkPackageImmediate/method')
      end

      context 'in project context' do
        let(:project) { FactoryBot.build_stubbed :project }

        it 'has no link to create work_packages' do
          is_expected
            .to_not have_json_path('_links/createWorkPackage')
        end

        it 'has no link to create work_packages immediately' do
          is_expected
            .to_not have_json_path('_links/createWorkPackageImmediate')
        end
      end
    end

    context 'when the user lacks the add_work_package permission' do
      before do
        allow(user)
          .to receive(:allowed_to?)
          .and_return(false)
      end

      it 'has no link to create work_packages' do
        is_expected
          .to_not have_json_path('_links/createWorkPackage')
      end

      it 'has no link to create work_packages immediately' do
        is_expected
          .to_not have_json_path('_links/createWorkPackageImmediate')
      end
    end

    context 'limited page size' do
      let(:page_size_parameter) { 2 }

      context 'on the first page' do
        it_behaves_like 'offset-paginated APIv3 collection' do
          let(:page) { 1 }
          let(:page_size) { page_size_parameter }
          let(:actual_count) { page_size_parameter }
          let(:collection_type) { 'WorkPackageCollection' }

          it_behaves_like 'links to next page by offset'
        end

        it_behaves_like 'has no link' do
          let(:link) { 'previousByOffset' }
        end
      end

      context 'on the last page' do
        let(:page_parameter) { 3 }

        it_behaves_like 'offset-paginated APIv3 collection' do
          let(:page) { 3 }
          let(:page_size) { page_size_parameter }
          let(:actual_count) { 1 }
          let(:collection_type) { 'WorkPackageCollection' }

          it_behaves_like 'links to previous page by offset'
        end

        it_behaves_like 'has no link' do
          let(:link) { 'nextByOffset' }
        end
      end
    end

    context 'passing a query hash' do
      let(:query) { { a: 'b', b: 'c' } }

      it_behaves_like 'has an untitled link' do
        let(:link) { 'self' }
        let(:href) { '/api/v3/example?a=b&b=c&offset=1&pageSize=30' }
      end
    end

    context 'passing groups' do
      let(:groups) do
        group = { 'custom': 'object' }
        allow(group).to receive(:has_sums?).and_return false
        [group]
      end

      it 'renders the groups object as json' do
        is_expected.to be_json_eql(groups.to_json).at_path('groups')
      end
    end

    context 'passing groups with sums' do
      let(:groups) do
        group = { 'sums': {} }
        allow(group).to receive(:has_sums?).and_return true
        [group]
      end

      it 'renders the groups object as json' do
        is_expected.to be_json_eql(groups.to_json).at_path('groups')
      end

      it 'has a link to the sums schema' do
        expected = {
          href: api_v3_paths.work_package_sums_schema
        }

        is_expected.to be_json_eql(expected.to_json).at_path('_links/sumsSchema')
      end
    end

    context 'passing sums' do
      let(:total_sums) { OpenStruct.new(estimated_hours: 1) }

      it 'renders the groups object as json' do
        expected = { 'estimatedTime': 'PT1H' }
        is_expected.to be_json_eql(expected.to_json).at_path('totalSums')
      end

      it 'has a link to the sums schema' do
        expected = {
          href: api_v3_paths.work_package_sums_schema
        }

        is_expected.to be_json_eql(expected.to_json).at_path('_links/sumsSchema')
      end
    end

    context 'passing schemas' do
      let(:embed_schemas) { true }

      it 'embeds a schema collection' do
        expected_path = api_v3_paths.work_package_schema(work_packages[0].project.id,
                                                         work_packages[0].type.id)

        is_expected
          .to be_json_eql(expected_path.to_json)
          .at_path('_embedded/schemas/_embedded/elements/0/_links/self/href')
      end
    end

    context 'with project admin priviliges' do
      # In this spec a user responds to `allowed_to` with true per default.
      let(:project) { FactoryBot.build_stubbed(:project) }

      it 'has a link to set the custom fields for that project' do
        expected = {
          href: "/projects/#{project.identifier}/settings/custom_fields",
          type: "text/html",
          title: "Custom fields"
        }

        is_expected
          .to be_json_eql(expected.to_json)
          .at_path('_links/customFields')
      end
    end

    context 'without project admin priviliges' do
      # In this spec a user responds to `allowed_to` with true per default.
      let(:project) { FactoryBot.build_stubbed(:project) }

      before do
        allow(user).to receive(:allowed_to?).with(:edit_project, project).and_return(false)
      end

      it 'has no link to set the custom fields for that project' do
        is_expected.to_not have_json_path('_links/customFields')
      end
    end

    context 'with project and general admin priviliges' do
      # In this spec a user responds to `allowed_to` with true per default.
      let(:project) { FactoryBot.build_stubbed(:project) }
      let(:user) { FactoryBot.build_stubbed(:admin) }

      before do
        allow(user).to receive(:allowed_to?).with(:edit_project, project).and_return(false)
      end

      it 'has a link to set the custom fields for that project' do
        expected = {
          href: "/projects/#{project.identifier}/settings/custom_fields",
          type: "text/html",
          title: "Custom fields"
        }

        is_expected
          .to be_json_eql(expected.to_json)
          .at_path('_links/customFields')
      end
    end

  end
end
