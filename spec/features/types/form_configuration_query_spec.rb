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

describe 'form query configuration', type: :feature, js: true do
  using_shared_fixtures :admin
  let(:type_bug) { FactoryBot.create :type_bug }
  let(:type_task) { FactoryBot.create :type_task }

  let(:project) { FactoryBot.create :project, types: [type_bug, type_task] }
  let(:other_project) { FactoryBot.create :project, types: [type_task] }
  let!(:work_package) do
    FactoryBot.create :work_package,
                      new_relation.merge(
                        project: project,
                        type: type_bug
                      )
  end
  let(:wp_relation_type) { :children }
  let(:frontend_relation_type) { wp_relation_type }
  let(:relation_target) { related_task }
  let(:new_relation) do
    relation = Hash.new
    relation[wp_relation_type] = [related_bug, related_task, related_task_other_project]
    relation
  end
  let!(:related_task) do
    FactoryBot.create :work_package, project: project, type: type_task
  end
  let!(:unrelated_task) do
    FactoryBot.create :work_package, subject: 'Unrelated task', type: type_task, project: project
  end
  let!(:unrelated_bug) do
    FactoryBot.create :work_package, subject: 'Unrelated bug', type: type_bug, project: project
  end
  let!(:related_task_other_project) do
    FactoryBot.create :work_package, project: other_project, type: type_task
  end
  let!(:related_bug) do
    FactoryBot.create :work_package, project: project, type: type_bug
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:form) { ::Components::Admin::TypeConfigurationForm.new }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { ::Components::WorkPackages::TableConfiguration::Filters.new }
  let(:columns) { ::Components::WorkPackages::Columns.new }

  describe "with EE token" do
    before do
      with_enterprise_token(:edit_attribute_groups)
      login_as(admin)
      visit edit_type_tab_path(id: type_bug.id, tab: "form_configuration")
    end

    it 'can save an empty query group' do
      form.add_query_group('Empty test', :children)
      form.save_changes
      expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)
      type_bug.reload

      query_group = type_bug.attribute_groups.detect { |x| x.is_a?(Type::QueryGroup) }
      expect(query_group.attributes).to be_kind_of(::Query)
      expect(query_group.key).to eq('Empty test')
    end

    it 'loads the children from the table split view (Regression #28490)' do
      form.add_query_group('Subtasks', :children)
      # Save changed query
      form.save_changes
      expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)


      # Visit wp_table
      wp_table.visit!
      wp_table.expect_work_package_listed work_package, related_task, related_bug

      # Open another ticket
      wp_table.open_split_view related_task

      # Open the parent ticket
      wp_split = wp_table.open_split_view work_package
      wp_split.ensure_page_loaded

      wp_split.expect_group('Subtasks') do
        embedded_table = Pages::EmbeddedWorkPackagesTable.new(find('.work-packages-embedded-view--container'))
        embedded_table.expect_work_package_listed related_task, related_bug
      end
    end

    context 'visiting a new work package screen' do
      let(:wp_page) { Pages::FullWorkPackageCreate.new }

      it 'does not show a subgroup (Regression #29582)' do
        form.add_query_group('Subtasks', :children)
        # Save changed query
        form.save_changes
        expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

        # Visit new wp page
        visit new_project_work_packages_path(project)

        wp_page.expect_no_group 'Subtasks'
        expect(page).to have_no_text 'Subtasks'
      end
    end

    it 'can modify and keep changed columns (Regression #27604)' do
      form.add_query_group('Columns Test', :children)
      form.edit_query_group('Columns Test')

      # Restrict filters to type_task
      modal.switch_to 'Columns'

      columns.assume_opened
      columns.uncheck_all save_changes: false
      columns.add 'ID', save_changes: false
      columns.add 'Subject', save_changes: false
      columns.apply

      # Save changed query
      form.save_changes
      expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

      type_bug.reload
      query = type_bug.attribute_groups.detect { |x| x.key == 'Columns Test' }
      expect(query).to be_present

      column_names = query.attributes.columns.map(&:name).sort
      expect(column_names).to eq %i[id subject]

      form.add_query_group('Second query', :children)
      form.edit_query_group('Second query')

      # Restrict filters to type_task
      modal.switch_to 'Columns'

      columns.assume_opened
      columns.uncheck_all save_changes: false
      columns.add 'ID', save_changes: false
      columns.apply

      # Save changed query
      form.save_changes
      expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

      type_bug.reload
      query = type_bug.attribute_groups.detect { |x| x.key == 'Columns Test' }
      expect(query).to be_present
      expect(query.attributes.show_hierarchies).to eq(false)

      column_names = query.attributes.columns.map(&:name).sort
      expect(column_names).to eq %i[id subject]

      query = type_bug.attribute_groups.detect { |x| x.key == 'Second query' }
      expect(query).to be_present
      expect(query.attributes.show_hierarchies).to eq(false)

      column_names = query.attributes.columns.map(&:name).sort
      expect(column_names).to eq %i[id]

      form.edit_query_group('Second query')
      modal.switch_to 'Columns'
      columns.expect_checked 'ID'
      columns.apply

      form.edit_query_group('Columns Test')
      modal.switch_to 'Columns'
      columns.expect_checked 'ID'
      columns.expect_checked 'Subject'
      columns.apply
    end

    shared_examples_for 'query group' do
      it '' do
        form.add_query_group('Subtasks', frontend_relation_type)
        form.edit_query_group('Subtasks')

        # Expect disabled tabs for timelines and display mode
        modal.expect_disabled_tab 'Gantt chart'
        modal.expect_disabled_tab 'Display settings'

        # Restrict filters to type_task
        modal.expect_open
        modal.switch_to 'Filters'
        # the templated filter should be hidden in the Filters tab
        filters.expect_filter_count 1
        filters.add_filter_by('Type', 'is', type_task.name)
        filters.save

        form.save_changes
        expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

        # Visit work package with that type
        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_group('Subtasks')
        table_container = find(".attributes-group[data-group-name='Subtasks']")
                            .find('.work-packages-embedded-view--container')
        embedded_table = Pages::EmbeddedWorkPackagesTable.new(table_container)
        embedded_table.expect_work_package_listed related_task, related_task_other_project
        embedded_table.ensure_work_package_not_listed! related_bug

        # Expect no reference to unrelated bug
        autocompleter = embedded_table.click_reference_inline_create
        results = embedded_table.search_autocomplete autocompleter,
                                                     query: 'Unrelated',
                                                     results_selector: '.ng-dropdown-panel-items'

        expect(results).to have_text "Task ##{unrelated_task.id} Unrelated task"
        expect(results).to have_no_text "Bug ##{unrelated_task.id} Unrelated bug"

        # Cancel that referencing
        page.find('.wp-create-relation--cancel').click

        # Reference the task type
        embedded_table.reference_work_package unrelated_task

        # Go back to type configuration
        visit edit_type_tab_path(id: type_bug.id, tab: "form_configuration")

        # Edit query to remove filters
        form.edit_query_group('Subtasks')

        # Expect filter still there
        modal.expect_open
        modal.switch_to 'Filters'
        filters.expect_filter_count 2
        filters.expect_filter_by 'Type', 'is', type_task.name

        # Remove the filter again
        filters.remove_filter 'type'
        filters.save

        # Save changes
        form.save_changes

        # Visit wp_page again, expect both listed
        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_group('Subtasks') do
          embedded_table = Pages::EmbeddedWorkPackagesTable.new(find('.work-packages-embedded-view--container'))
          embedded_table.expect_work_package_listed related_task, related_bug, unrelated_task
        end
      end
    end

    context 'children table' do
      it_behaves_like 'query group'
    end

    context 'relates_to table' do
      it_behaves_like 'query group' do
        let(:wp_relation_type) { :relates_to }
        let(:frontend_relation_type) { :relates }
        let(:relation_target) { [work_package] }
      end
    end

    context 'blocks table' do
      it_behaves_like 'query group' do
        let(:wp_relation_type) { :blocks }
        let(:relation_target) { [work_package] }
      end
    end
  end
end
