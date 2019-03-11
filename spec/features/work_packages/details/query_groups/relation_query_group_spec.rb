#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'Work package with relation query group', js: true, selenium: true do
  include_context 'ui-autocomplete helpers'

  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project }
  let(:relation_type) { :parent }
  let(:relation_target) { work_package }
  let(:new_relation) do
    rel = Hash.new
    rel[relation_type] = relation_target
    rel
  end
  let(:type) do
    FactoryBot.create :type_with_relation_query_group,
                      relation_filter: relation_type
  end
  let!(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type
  end
  let!(:related_work_package) do
    FactoryBot.create :work_package,
                      new_relation.merge(
                        project: project,
                        type: type
                      )
  end

  let(:work_packages_page) { ::Pages::SplitWorkPackage.new(work_package) }
  let(:full_wp) { ::Pages::FullWorkPackage.new(work_package) }
  let(:relations) { ::Components::WorkPackages::Relations.new(work_package) }
  let(:tabs) { ::Components::WorkPackages::Tabs.new(work_package) }
  let(:relations_tab) { find('.tabrow li', text: 'RELATIONS') }
  let(:embedded_table) { Pages::EmbeddedWorkPackagesTable.new(first('wp-single-view .work-packages-embedded-view--container')) }

  # let(:visit) { true }

  before do
    # inline create needs defaults
    status = work_package.status
    status.update_attribute :is_default, true
    priority = work_package.priority
    priority.update_attribute :is_default, true

    login_as user
    full_wp.visit!
    full_wp.ensure_page_loaded
  end

  context 'children table' do
    it 'creates and removes across all tables' do
      embedded_table.expect_work_package_count 1
      relations_tab.click
      relations.expect_child(related_work_package)

      # Create new work package within embedded table
      embedded_table.table_container.find("a", text: I18n.t('js.relation_buttons.add_new_child')).click
      subject_field = embedded_table.edit_field(nil, :subject)
      subject_field.expect_active!
      subject_field.set_value("Fresh WP\n")

      # Expect work package existence propagated to all tables
      expect(embedded_table.table_container).to have_text("Fresh WP")
      expect(relations.children_table).to have_text("Fresh WP")

      # removing work package from embedded table will also remove it from relations tab
      row = ".wp-row-#{related_work_package.id}-table"
      embedded_table.table_container.find(row).hover
      embedded_table.table_container.find("#{row} .wp-table-action--unlink").click
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_not_listed(related_work_package)
      end
      relations.expect_not_child(related_work_package)

    end
  end

  context 'follower table' do
    let(:relation_type) { :follows }
    let(:relation_target) { [work_package] }
    let!(:independent_work_package) do
      FactoryBot.create :work_package,
                        project: project
    end

    before do
      embedded_table.expect_work_package_listed related_work_package
      relations_tab.click
      relations.expect_relation(related_work_package)
    end

    it 'creates and removes across all tables' do
      embedded_table.table_container.find('a', text: I18n.t('js.relation_buttons.create_new')).click
      subject_field = embedded_table.edit_field(nil, :subject)
      subject_field.expect_active!
      subject_field.set_value("Fresh WP\n")

      expect(embedded_table.table_container).to have_text('Fresh WP', wait: 10)
      relations.expect_relation_by_text('Fresh WP')
    end

    it 'add existing, remove it, add it from relations tab, remove from relations tab' do
      embedded_table.table_container.find('a', text: I18n.t('js.relation_buttons.add_existing')).click
      container = embedded_table.table_container.find('.wp-relations-create--form', wait: 10)
      autocomplete = page.find(".wp-relations--autocomplete")
      select_autocomplete autocomplete,
                          results_selector: '.wp-relations-autocomplete--results',
                          query: independent_work_package.subject,
                          select_text: independent_work_package.subject

      container.find('.wp-create-relation--save').click
      embedded_table.expect_work_package_listed(independent_work_package)
      relations.expect_relation(independent_work_package)

      # removing work package from embedded table will also remove it from relations tab
      row = ".wp-row-#{independent_work_package.id}-table"
      embedded_table.table_container.find(row).hover
      embedded_table.table_container.find("#{row} .wp-table-action--unlink").click
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_not_listed(independent_work_package)
      end
      within(relations.relations_group) do
        relations.expect_no_relation(independent_work_package)
      end

      # adding existing from relations tab
      relations.add_relation type: ::Relation::TYPES[relation_type.to_s][:sym], to: independent_work_package
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_listed(independent_work_package)
      end
      relations.expect_relation(independent_work_package)

      # Check that deletion of relations still work after a page reload
      full_wp.visit!
      relations_tab = find('.tabrow li', text: 'RELATIONS')
      relations = Components::WorkPackages::Relations.new(work_package)
      embedded_table = Pages::EmbeddedWorkPackagesTable.new(first('wp-single-view .work-packages-embedded-view--container'))

      embedded_table.table_container.find(".wp-row-#{independent_work_package.id}-table").hover
      embedded_table.table_container.find("#{row} .wp-table-action--unlink").click
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_not_listed(independent_work_package)
      end
      relations_tab.click
      within(relations.relations_group) do
        relations.expect_no_relation(independent_work_package)
      end

      # adding existing from relations tab will show work package also in the embedded table
      relations.add_relation type: ::Relation::TYPES[relation_type.to_s][:sym], to: independent_work_package
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_listed(independent_work_package)
      end
      relations.expect_relation(independent_work_package)

      # removing relation from relations tab removes it from embedded table, too
      relations.remove_relation independent_work_package
      within(embedded_table.table_container) do
        embedded_table.expect_work_package_not_listed(independent_work_package)
      end
    end
  end
end
