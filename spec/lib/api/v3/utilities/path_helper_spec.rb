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

describe ::API::V3::Utilities::PathHelper do
  let(:helper) { Class.new.tap { |c| c.extend(::API::V3::Utilities::PathHelper) }.api_v3_paths }

  shared_examples_for 'path' do |url|
    it 'provides the path' do
      is_expected.to match(url)
    end

    it 'prepends the sub uri if configured' do
      allow(OpenProject::Configuration).to receive(:rails_relative_url_root)
        .and_return('/open_project')

      is_expected.to match("/open_project#{url}")
    end
  end

  before(:each) do
    RequestStore.store[:cached_root_path] = nil
  end

  after(:each) do
    RequestStore.clear!
  end

  shared_examples_for 'api v3 path' do |url|
    it_behaves_like 'path', "/api/v3#{url}"
  end

  describe '#root' do
    subject { helper.root }

    it_behaves_like 'api v3 path'
  end

  describe '#activity' do
    subject { helper.activity 1 }

    it_behaves_like 'api v3 path', '/activities/1'
  end

  describe '#attachment' do
    subject { helper.attachment 1 }

    it_behaves_like 'api v3 path', '/attachments/1'
  end

  describe '#attachment_download without file name' do
    subject { helper.attachment_download 1 }

    it_behaves_like 'path', '/attachments/1'
  end

  describe '#attachment_download with file name' do
    subject { helper.attachment_download 1, 'file.png' }

    it_behaves_like 'path', '/attachments/1/file.png'
  end

  describe '#attachments_by_work_package' do
    subject { helper.attachments_by_work_package 1 }

    it_behaves_like 'api v3 path', '/work_packages/1/attachments'
  end

  describe '#available_assignees' do
    subject { helper.available_assignees 42 }

    it_behaves_like 'api v3 path', '/projects/42/available_assignees'
  end

  describe '#available_responsibles' do
    subject { helper.available_responsibles 42 }

    it_behaves_like 'api v3 path', '/projects/42/available_responsibles'
  end

  describe '#available_watchers' do
    subject { helper.available_watchers 42 }

    it_behaves_like 'api v3 path', '/work_packages/42/available_watchers'
  end

  describe '#available_projects_on_edit' do
    subject { helper.available_projects_on_edit 42 }

    it_behaves_like 'api v3 path', '/work_packages/42/available_projects'
  end

  describe '#available_projects_on_create' do
    subject { helper.available_projects_on_create }

    it_behaves_like 'api v3 path', '/work_packages/available_projects'
  end

  describe '#categories' do
    subject { helper.categories 42 }

    it_behaves_like 'api v3 path', '/projects/42/categories'
  end

  describe '#category' do
    subject { helper.category 42 }

    it_behaves_like 'api v3 path', '/categories/42'
  end

  describe '#configuration' do
    subject { helper.configuration }

    it_behaves_like 'api v3 path', '/configuration'
  end

  describe '#custom_option' do
    subject { helper.custom_option 42 }

    it_behaves_like 'api v3 path', '/custom_options/42'
  end

  describe '#create_work_package_form' do
    subject { helper.create_work_package_form }

    it_behaves_like 'api v3 path', '/work_packages/form'
  end

  describe '#create_project_work_package_form' do
    subject { helper.create_project_work_package_form 42 }

    it_behaves_like 'api v3 path', '/projects/42/work_packages/form'
  end

  describe '#my_preferences' do
    subject { helper.my_preferences }

    it_behaves_like 'api v3 path', '/my_preferences'
  end

  describe '#render_markup' do
    subject { helper.render_markup(format: 'super_fancy', link: 'link-ish') }

    before do
      allow(Setting).to receive(:text_formatting).and_return('by-the-settings')
    end

    it_behaves_like 'api v3 path', '/render/super_fancy?context=link-ish'

    context 'no link given' do
      subject { helper.render_markup(format: 'super_fancy') }

      it { is_expected.to eql('/api/v3/render/super_fancy') }
    end

    context 'no format given' do
      subject { helper.render_markup }

      it { is_expected.to eql('/api/v3/render/by-the-settings') }

      context 'settings set to no formatting' do
        subject { helper.render_markup }

        before do
          allow(Setting).to receive(:text_formatting).and_return('')
        end

        it { is_expected.to eql('/api/v3/render/plain') }
      end
    end
  end

  describe '#principals' do
    subject { helper.principals }

    it_behaves_like 'api v3 path', '/principals'
  end

  describe 'priorities paths' do
    describe '#priorities' do
      subject { helper.priorities }

      it_behaves_like 'api v3 path', '/priorities'
    end

    describe '#priority' do
      subject { helper.priority 1 }

      it_behaves_like 'api v3 path', '/priorities/1'
    end
  end

  describe 'projects paths' do
    describe '#projects' do
      subject { helper.projects }

      it_behaves_like 'api v3 path', '/projects'
    end

    describe '#project' do
      subject { helper.project 1 }

      it_behaves_like 'api v3 path', '/projects/1'
    end
  end

  describe '#queries' do
    subject { helper.queries }

    it_behaves_like 'api v3 path', '/queries'
  end

  describe '#query' do
    subject { helper.query 1 }

    it_behaves_like 'api v3 path', '/queries/1'
  end

  describe '#query_default' do
    subject { helper.query_default }

    it_behaves_like 'api v3 path', '/queries/default'
  end

  describe '#query_project_default' do
    subject { helper.query_project_default(42) }

    it_behaves_like 'api v3 path', '/projects/42/queries/default'
  end

  describe '#create_query_form' do
    subject { helper.create_query_form }

    it_behaves_like 'api v3 path', '/queries/form'
  end

  describe '#query_form' do
    subject { helper.query_form(42) }

    it_behaves_like 'api v3 path', '/queries/42/form'
  end

  describe '#query_star' do
    subject { helper.query_star 1 }

    it_behaves_like 'api v3 path', '/queries/1/star'
  end

  describe '#query_unstar' do
    subject { helper.query_unstar 1 }

    it_behaves_like 'api v3 path', '/queries/1/unstar'
  end

  describe '#query_column' do
    subject { helper.query_column 'updated_on' }

    it_behaves_like 'api v3 path', '/queries/columns/updated_on'
  end

  describe '#query_group_by' do
    subject { helper.query_group_by 'status' }

    it_behaves_like 'api v3 path', '/queries/group_bys/status'
  end

  describe '#query_sort_by' do
    subject { helper.query_sort_by 'status', 'desc' }

    it_behaves_like 'api v3 path', '/queries/sort_bys/status-desc'
  end

  describe '#query_filter' do
    subject { helper.query_filter 'status' }

    it_behaves_like 'api v3 path', '/queries/filters/status'
  end

  describe '#query_filter_instance_schemas' do
    subject { helper.query_filter_instance_schemas }

    it_behaves_like 'api v3 path', '/queries/filter_instance_schemas'
  end

  describe '#query_filter_instance_schema' do
    subject { helper.query_filter_instance_schema('bogus') }

    it_behaves_like 'api v3 path', '/queries/filter_instance_schemas/bogus'
  end

  describe '#query_project_form' do
    subject { helper.query_project_form(42) }

    it_behaves_like 'api v3 path', '/projects/42/queries/form'
  end

  describe '#query_project_filter_instance_schemas' do
    subject { helper.query_project_filter_instance_schemas(42) }

    it_behaves_like 'api v3 path', '/projects/42/queries/filter_instance_schemas'
  end

  describe '#query_operator' do
    subject { helper.query_operator '=' }

    it_behaves_like 'api v3 path', '/queries/operators/='
  end

  describe '#query_schema' do
    subject { helper.query_schema }

    it_behaves_like 'api v3 path', '/queries/schema'
  end

  describe '#query_project_schema' do
    subject { helper.query_project_schema('42') }

    it_behaves_like 'api v3 path', '/projects/42/queries/schema'
  end

  describe '#query_available_projects' do
    subject { helper.query_available_projects }

    it_behaves_like 'api v3 path', '/queries/available_projects'
  end

  describe 'relations paths' do
    describe '#relation' do
      subject { helper.relation 1 }

      it_behaves_like 'api v3 path', '/relations'
    end

    describe '#relation' do
      subject { helper.relation 1 }

      it_behaves_like 'api v3 path', '/relations/1'
    end
  end

  describe 'revisions paths' do
    describe '#revision' do
      subject { helper.revision 1 }

      it_behaves_like 'api v3 path', '/revisions/1'
    end

    describe '#show_revision' do
      subject { helper.show_revision 'foo', 1234 }

      it_behaves_like 'path', '/projects/foo/repository/revision/1234'
    end
  end

  describe '#roles' do
    subject { helper.roles }

    it_behaves_like 'api v3 path', '/roles'
  end

  describe '#role' do
    subject { helper.role 12 }

    it_behaves_like 'api v3 path', '/roles/12'
  end

  describe 'schemas paths' do
    describe '#work_package_schema' do
      subject { helper.work_package_schema 1, 2 }

      it_behaves_like 'api v3 path', '/work_packages/schemas/1-2'
    end

    describe '#work_package_schemas' do
      subject { helper.work_package_schemas }

      it_behaves_like 'api v3 path', '/work_packages/schemas'
    end

    describe '#work_package_schemas with filters' do
      subject { helper.work_package_schemas [1, 2], [3, 4] }

      def self.filter
        CGI.escape([{ id: { operator: '=', values: ['1-2', '3-4'] } }].to_s)
      end

      it_behaves_like 'api v3 path',
                      "/work_packages/schemas?filters=#{filter}"
    end

    describe '#work_package_sums_schema' do
      subject { helper.work_package_sums_schema }

      it_behaves_like 'api v3 path', '/work_packages/schemas/sums'
    end
  end

  describe 'statuses paths' do
    describe '#statuses' do
      subject { helper.statuses }

      it_behaves_like 'api v3 path', '/statuses'
    end

    describe '#status' do
      subject { helper.status 1 }

      it_behaves_like 'api v3 path', '/statuses/1'
    end
  end

  describe 'string object paths' do
    describe '#string_object' do
      subject { helper.string_object 'foo' }

      it_behaves_like 'api v3 path', '/string_objects?value=foo'

      it 'escapes correctly' do
        value = 'foo/bar baz'
        expect(helper.string_object(value)).to eql('/api/v3/string_objects?value=foo%2Fbar%20baz')
      end
    end

    describe '#status' do
      subject { helper.status 1 }

      it_behaves_like 'api v3 path', '/statuses/1'
    end
  end

  describe 'types paths' do
    describe '#types' do
      subject { helper.types }

      it_behaves_like 'api v3 path', '/types'
    end

    describe '#types_by_project' do
      subject { helper.types_by_project 12 }

      it_behaves_like 'api v3 path', '/projects/12/types'
    end

    describe '#type' do
      subject { helper.type 1 }

      it_behaves_like 'api v3 path', '/types/1'
    end
  end

  describe 'users paths' do
    describe '#users' do
      subject { helper.users }

      it_behaves_like 'api v3 path', '/users'
    end

    describe '#user' do
      subject { helper.user 1 }

      it_behaves_like 'api v3 path', '/users/1'
    end
  end

  describe '#version' do
    subject { helper.version 42 }

    it_behaves_like 'api v3 path', '/versions/42'
  end

  describe '#versions' do
    subject { helper.versions }

    it_behaves_like 'api v3 path', '/versions'
  end

  describe '#versions_by_project' do
    subject { helper.versions_by_project 42 }

    it_behaves_like 'api v3 path', '/projects/42/versions'
  end

  describe '#projects_by_version' do
    subject { helper.projects_by_version 42 }

    it_behaves_like 'api v3 path', '/versions/42/projects'
  end

  describe '#work_packages_by_project' do
    subject { helper.work_packages_by_project 42 }

    it_behaves_like 'api v3 path', '/projects/42/work_packages'
  end

  describe 'work packages paths' do
    describe '#work_packages' do
      subject { helper.work_packages }

      it_behaves_like 'api v3 path', '/work_packages'
    end

    describe '#work_package' do
      subject { helper.work_package 1 }

      it_behaves_like 'api v3 path', '/work_packages/1'
    end

    describe '#work_package_activities' do
      subject { helper.work_package_activities 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/activities'
    end

    describe '#work_package_relations' do
      subject { helper.work_package_relations 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/relations'
    end

    describe '#work_package_relation' do
      subject { helper.work_package_relation 1, 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/relations/1'
    end

    describe '#work_package_revisions' do
      subject { helper.work_package_revisions 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/revisions'
    end

    describe '#work_package_form' do
      subject { helper.work_package_form 1 }

      it_behaves_like 'api v3 path', '/work_packages/1/form'
    end

    describe '#work_package_watchers' do
      subject { helper.work_package_watchers 1 }

      it_behaves_like 'api v3 path', '/work_packages/1/watchers'
    end

    describe '#watcher' do
      subject { helper.watcher 1, 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/watchers/1'
    end
  end
end
