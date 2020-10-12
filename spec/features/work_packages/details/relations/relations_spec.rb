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

describe 'Work package relations tab', js: true, selenium: true do
  include_context 'ng-select-autocomplete helpers'

  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create :project }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:work_packages_page) { ::Pages::SplitWorkPackage.new(work_package) }
  let(:full_wp) { ::Pages::FullWorkPackage.new(work_package) }
  let(:relations) { ::Components::WorkPackages::Relations.new(work_package) }
  let(:tabs) { ::Components::WorkPackages::Tabs.new(work_package) }

  let(:relations_tab) { find('.tabrow li.selected', text: 'RELATIONS') }

  let(:visit) { true }

  before do
    login_as user

    if visit
      visit_relations
    end
  end

  def visit_relations
    work_packages_page.visit_tab!('relations')
    expect_angular_frontend_initialized
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  describe 'relation group-by toggler' do
    let(:project) { FactoryBot.create :project, types: [type_1, type_2] }
    let(:type_1) { FactoryBot.create :type }
    let(:type_2) { FactoryBot.create :type }

    let(:to_1) { FactoryBot.create(:work_package, type: type_1, project: project) }
    let(:to_2) { FactoryBot.create(:work_package, type: type_2, project: project) }

    let!(:relation_1) do
      FactoryBot.create :relation,
                         from: work_package,
                         to: to_1,
                         relation_type: Relation::TYPE_FOLLOWS
    end
    let!(:relation_2) do
      FactoryBot.create :relation,
                         from: work_package,
                         to: to_2,
                         relation_type: Relation::TYPE_RELATES
    end

    let(:toggle_btn_selector) { '#wp-relation-group-by-toggle' }
    let(:visit) { false }

    before do
      visit_relations

      work_packages_page.visit_tab!('relations')
      work_packages_page.expect_subject
      loading_indicator_saveguard

      scroll_to_element find('.detail-panel--relations')
    end

    it 'allows to toggle how relations are grouped' do
      # Expect to be grouped by relation type by default
      expect(page).to have_selector(toggle_btn_selector,
                                    text: 'Group by work package type', wait: 20)

      expect(page).to have_selector('.relation-group--header', text: 'FOLLOWS')
      expect(page).to have_selector('.relation-group--header', text: 'RELATED TO')

      expect(page).to have_selector('.relation-row--type', text: type_1.name)
      expect(page).to have_selector('.relation-row--type', text: type_2.name)

      find(toggle_btn_selector).click
      expect(page).to have_selector(toggle_btn_selector, text: 'Group by relation type', wait: 10)

      expect(page).to have_selector('.relation-group--header', text: type_1.name.upcase)
      expect(page).to have_selector('.relation-group--header', text: type_2.name.upcase)

      expect(page).to have_selector('.relation-row--type', text: 'Follows')
      expect(page).to have_selector('.relation-row--type', text: 'Related To')
    end

    it 'allows to edit relation types when toggled' do
      find(toggle_btn_selector).click
      expect(page).to have_selector(toggle_btn_selector, text: 'Group by relation type', wait: 20)

      # Expect current to be follows and other one related
      expect(page).to have_selector('.relation-row--type', text: 'Follows')
      expect(page).to have_selector('.relation-row--type', text: 'Related To')

      # edit to blocks
      relations.edit_relation_type(to_1, to_type: 'Blocks')

      # the other one should not be altered
      expect(page).to have_selector('.relation-row--type', text: 'Blocks')
      expect(page).to have_selector('.relation-row--type', text: 'Related To')

      updated_relation = Relation.find(relation_1.id)
      expect(updated_relation.relation_type).to eq('blocks')
      expect(updated_relation.from_id).to eq(work_package.id)
      expect(updated_relation.to_id).to eq(to_1.id)

      relations.edit_relation_type(to_1, to_type: 'Blocked by')

      expect(page).to have_selector('.relation-row--type', text: 'Blocked by')
      expect(page).to have_selector('.relation-row--type', text: 'Related To')

      updated_relation = Relation.find(relation_1.id)
      expect(updated_relation.relation_type).to eq('blocks')
      expect(updated_relation.from_id).to eq(to_1.id)
      expect(updated_relation.to_id).to eq(work_package.id)
    end
  end

  describe 'with limited permissions' do
    let(:permissions) { %i(view_work_packages) }
    let(:user_role) do
      FactoryBot.create :role, permissions: permissions
    end

    let(:user) do
      FactoryBot.create :user,
                         member_in_project: project,
                         member_through_role: user_role
    end

    context 'as view-only user, with parent set' do
      let(:work_package) { FactoryBot.create(:work_package, project: project) }

      it 'shows no links to create relations' do
        # No create buttons should exist
        expect(page).to have_no_selector('.wp-relations-create-button')

        # Test for add relation
        expect(page).to have_no_selector('#relation--add-relation')
      end
    end

    context 'with relations permissions' do
      let(:permissions) do
        %i(view_work_packages add_work_packages manage_subtasks manage_work_package_relations)
      end

      let!(:relatable) { FactoryBot.create(:work_package, project: project) }
      it 'should allow to manage relations' do
        relations.add_relation(type: 'follows', to: relatable)

        # Relations counter badge should increase number of relations
        tabs.expect_counter(relations_tab, 1)

        relations.remove_relation(relatable)
        expect(page).to have_no_selector('.relation-group--header', text: 'FOLLOWS')

        # If there are no relations, the counter badge should not be displayed
        tabs.expect_no_counter(relations_tab)

        work_package.reload
        expect(work_package.relations.direct).to be_empty
      end

      it 'should allow to move between split and full view (Regression #24194)' do
        relations.add_relation(type: 'follows', to: relatable)
        # Relations counter should increase
        tabs.expect_counter(relations_tab, 1)

        # Switch to full view
        find('.work-packages--details-fullscreen-icon').click

        # Expect to have row
        relations.hover_action(relatable, :delete)

        expect(page).to have_no_selector('.relation-group--header', text: 'FOLLOWS')
        expect(page).to have_no_selector('.wp-relations--subject-field', text: relatable.subject)

        # Back to split view
        page.execute_script('window.history.back()')
        work_packages_page.expect_subject

        expect(page).to have_no_selector('.relation-group--header', text: 'FOLLOWS')
        expect(page).to have_no_selector('.wp-relations--subject-field', text: relatable.subject)
      end

      it 'should follow the relation links (Regression #26794)' do
        relations.add_relation(type: 'follows', to: relatable)

        relations.click_relation(relatable)
        subject = full_wp.edit_field(:subject)
        subject.expect_state_text relatable.subject

        relations.click_relation(work_package)
        subject = full_wp.edit_field(:subject)
        subject.expect_state_text work_package.subject
      end

      it 'should allow to change relation descriptions' do
        relations.add_relation(type: 'follows', to: relatable)

        ## Toggle description
        relations.hover_action(relatable, :info)

        # Open textarea
        created_row = relations.find_row(relatable)
        created_row.find('.wp-relation--description-read-value.-placeholder',
                         text: I18n.t('js.placeholders.relation_description')).click

        expect(page).to have_focus_on('.wp-relation--description-textarea')
        textarea = created_row.find('.wp-relation--description-textarea')
        textarea.set 'my description!'

        # Save description
        created_row.find('.inplace-edit--control--save a').click

        loading_indicator_saveguard

        # Wait for the relations table to be present
        sleep 2
        expect(page).to have_selector('.wp-relations--subject-field')

        scroll_to_element find('.detail-panel--relations')

        ## Toggle description again
        retry_block do
          relations.hover_action(relatable, :info)
          created_row = relations.find_row(relatable)

          find'.wp-relation--description-read-value'
        end

        created_row.find('.wp-relation--description-read-value',
                         text: 'my description!').click

        # Cancel edition
        created_row.find('.inplace-edit--control--cancel a').click
        created_row.find('.wp-relation--description-read-value',
                         text: 'my description!').click

        relation = work_package.relations.direct.first
        relation.reload
        expect(relation.description).to eq('my description!')

        # Toggle to close
        relations.hover_action(relatable, :info)
        expect(created_row).to have_no_selector('.wp-relation--description-read-value')
      end
    end
  end
end
