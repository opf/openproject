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

  shared_examples_for 'index' do |name|
    plural_name = name.to_s.pluralize

    describe "##{plural_name}" do
      subject { helper.send(plural_name) }

      it_behaves_like 'api v3 path', "/#{plural_name}"
    end
  end

  shared_examples_for 'show' do |name|
    describe "##{name}" do
      subject { helper.send(:"#{name}", 42) }

      it_behaves_like 'api v3 path', "/#{name.to_s.pluralize}/42"
    end
  end

  shared_examples_for 'create form' do |name|
    describe "#create_#{name}_form" do
      subject { helper.send(:"create_#{name}_form") }

      it_behaves_like 'api v3 path', "/#{name.to_s.pluralize}/form"
    end
  end

  shared_examples_for 'update form' do |name|
    describe "##{name}_form" do
      subject { helper.send(:"#{name}_form", 42) }

      it_behaves_like 'api v3 path', "/#{name.to_s.pluralize}/42/form"
    end
  end

  shared_examples_for 'schema' do |name|
    describe "##{name}_schema" do
      subject { helper.send(:"#{name}_schema") }

      it_behaves_like 'api v3 path', "/#{name.to_s.pluralize}/schema"
    end
  end

  shared_examples_for 'resource' do |name, except: []|
    it_behaves_like('index', name) unless except.include?(:index)
    it_behaves_like('show', name) unless except.include?(:show)
    it_behaves_like('update form', name) unless except.include?(:update_form)
    it_behaves_like('create form', name) unless except.include?(:create_form)
    it_behaves_like('schema', name) unless except.include?(:schema)
  end

  describe '#root' do
    subject { helper.root }

    it_behaves_like 'api v3 path'
  end

  context 'activities paths' do
    it_behaves_like 'show', :activity
  end

  context 'attachments paths' do
    it_behaves_like 'index', :attachment
    it_behaves_like 'show', :attachment

    describe '#attachment_content' do
      subject { helper.attachment_content 1 }

      it_behaves_like 'api v3 path', '/attachments/1/content'
    end

    describe '#attachments_by_post' do
      subject { helper.attachments_by_post 1 }

      it_behaves_like 'api v3 path', '/posts/1/attachments'
    end

    describe '#attachments_by_work_package' do
      subject { helper.attachments_by_work_package 1 }

      it_behaves_like 'api v3 path', '/work_packages/1/attachments'
    end

    describe '#attachments_by_wiki_page' do
      subject { helper.attachments_by_wiki_page 1 }

      it_behaves_like 'api v3 path', '/wiki_pages/1/attachments'
    end
  end

  context 'category paths' do
    it_behaves_like 'index', :category
    it_behaves_like 'show', :category

    describe '#categories_by_project' do
      subject { helper.categories_by_project 42 }

      it_behaves_like 'api v3 path', '/projects/42/categories'
    end
  end

  context 'configuration paths' do
    describe '#configuration' do
      subject { helper.configuration }

      it_behaves_like 'api v3 path', '/configuration'
    end
  end

  context 'custom action paths' do
    it_behaves_like 'show', :custom_action

    describe '#custom_action_execute' do
      subject { helper.custom_action_execute 42 }

      it_behaves_like 'api v3 path', '/custom_actions/42/execute'
    end

    it_behaves_like 'show', :custom_option
  end

  describe 'memberships paths' do
    it_behaves_like 'resource', :membership

    describe '#memberships_available_projects' do
      subject { helper.memberships_available_projects }

      it_behaves_like 'api v3 path', '/memberships/available_projects'
    end
  end

  describe 'messages paths' do
    it_behaves_like 'index', :message
    it_behaves_like 'show', :message
  end

  describe 'my paths' do
    describe '#my_preferences' do
      subject { helper.my_preferences }

      it_behaves_like 'api v3 path', '/my_preferences'
    end
  end

  describe 'news paths' do
    describe '#newses' do
      subject { helper.newses }

      it_behaves_like 'api v3 path', '/news'
    end

    it_behaves_like 'show', :news
  end

  describe 'markup paths' do
    describe '#render_markup' do
      subject { helper.render_markup(link: 'link-ish') }

      it_behaves_like 'api v3 path', '/render/markdown?context=link-ish'

      context 'no link given' do
        subject { helper.render_markup }

        it { is_expected.to eql('/api/v3/render/markdown') }
      end
    end
  end

  describe 'posts paths' do
    it_behaves_like 'index', :post
    it_behaves_like 'show', :post
  end

  describe 'principals paths' do
    it_behaves_like 'index', :principals
  end

  describe 'priorities paths' do
    it_behaves_like 'index', :priority
    it_behaves_like 'show', :priority
  end

  describe 'projects paths' do
    it_behaves_like 'resource', :project

    describe '#projects_available_parents' do
      subject { helper.projects_available_parents }

      it_behaves_like 'api v3 path', '/projects/available_parent_projects'
    end
  end

  describe 'query paths' do
    it_behaves_like 'resource', :query

    describe '#query_default' do
      subject { helper.query_default }

      it_behaves_like 'api v3 path', '/queries/default'
    end

    describe '#query_project_default' do
      subject { helper.query_project_default(42) }

      it_behaves_like 'api v3 path', '/projects/42/queries/default'
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

    describe '#query_project_schema' do
      subject { helper.query_project_schema('42') }

      it_behaves_like 'api v3 path', '/projects/42/queries/schema'
    end

    describe '#query_available_projects' do
      subject { helper.query_available_projects }

      it_behaves_like 'api v3 path', '/queries/available_projects'
    end
  end

  describe 'relations paths' do
    it_behaves_like 'index', :relation
    it_behaves_like 'show', :relation
  end

  describe 'revisions paths' do
    it_behaves_like 'show', :revision

    describe '#show_revision' do
      subject { helper.show_revision 'foo', 1234 }

      it_behaves_like 'path', '/projects/foo/repository/revision/1234'
    end
  end

  describe 'roles paths' do
    it_behaves_like 'index', :role
    it_behaves_like 'show', :role
  end

  describe 'statuses paths' do
    it_behaves_like 'index', :status
    it_behaves_like 'show', :status
  end

  describe 'grids paths' do
    it_behaves_like 'resource', :grid
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
  end

  context 'status paths' do
    it_behaves_like 'show', :status
  end

  context 'time_entry paths' do
    it_behaves_like 'resource', :time_entry

    describe '#time_entries_activity' do
      subject { helper.time_entries_activity 42 }

      it_behaves_like 'api v3 path', '/time_entries/activities/42'
    end

    describe '#time_entries_available_projects' do
      subject { helper.time_entries_available_projects }

      it_behaves_like 'api v3 path', '/time_entries/available_projects'
    end
  end

  describe 'types paths' do
    it_behaves_like 'index', :type
    it_behaves_like 'show', :type

    describe '#types_by_project' do
      subject { helper.types_by_project 12 }

      it_behaves_like 'api v3 path', '/projects/12/types'
    end
  end

  describe 'users paths' do
    it_behaves_like 'index', :user
    it_behaves_like 'show', :user
  end

  describe 'group paths' do
    describe '#group' do
      subject { helper.group 1 }

      it_behaves_like 'api v3 path', '/groups/1'
    end
  end

  describe 'version paths' do
    it_behaves_like 'resource', :version

    describe '#versions_available_projects' do
      subject { helper.versions_available_projects }

      it_behaves_like 'api v3 path', '/versions/available_projects'
    end

    describe '#versions_by_project' do
      subject { helper.versions_by_project 42 }

      it_behaves_like 'api v3 path', '/projects/42/versions'
    end

    describe '#projects_by_version' do
      subject { helper.projects_by_version 42 }

      it_behaves_like 'api v3 path', '/versions/42/projects'
    end
  end

  describe 'wiki pages paths' do
    it_behaves_like 'show', :wiki_page
  end

  describe 'work packages paths' do
    it_behaves_like 'resource', :work_package, except: [:schema]

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

    describe '#work_package_watchers' do
      subject { helper.work_package_watchers 1 }

      it_behaves_like 'api v3 path', '/work_packages/1/watchers'
    end

    describe '#work_packages_by_project' do
      subject { helper.work_packages_by_project 42 }

      it_behaves_like 'api v3 path', '/projects/42/work_packages'
    end

    describe '#create_project_work_package_form' do
      subject { helper.create_project_work_package_form 42 }

      it_behaves_like 'api v3 path', '/projects/42/work_packages/form'
    end

    describe '#watcher' do
      subject { helper.watcher 1, 42 }

      it_behaves_like 'api v3 path', '/work_packages/42/watchers/1'
    end

    describe 'available ... paths' do
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
        subject { helper.available_projects_on_create(nil) }

        it_behaves_like 'api v3 path', '/work_packages/available_projects'
      end

      describe '#available_projects_on_create with type' do
        subject { helper.available_projects_on_create(1) }

        it_behaves_like 'api v3 path', '/work_packages/available_projects?for_type=1'
      end
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
  end
end
