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

describe 'My project page editing', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:overview) { FactoryBot.create :my_projects_overview, project: project }
  let(:mypage) { ::Pages::Page.new }

  let(:button_selector) { '.toolbar a.button' }

  let(:user) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: role }
  let(:role) { FactoryBot.create :role, permissions: [:view_project,
                                                      :view_work_packages,
                                                      :edit_work_packages,
                                                      :edit_project] }

  # Add block select
  let(:select) { find('#block-select') }

  # Save button
  let(:save_changes) { find('#save-block-form input[type=submit]') }

  let(:editor) { ::Components::WysiwygEditor.new '#block_a' }

  # Block positions
  # Do not use let since it occasionally causes stale refernces
  def top
    find('#list-top')
  end

  def left
    find('#list-left')
  end

  def right
    find('#list-right')
  end

  def hidden
    find('#list-hidden')
  end

  def find_block(el, name)
    el.find("#block_#{name}")
  end

  def expect_block(el, name)
    expect(el).to have_selector("#block_#{name}")
  end

  def drag_to(name, from, to)
    # Expect from
    expect_block(from, name)

    # Move
    # I've tried with Capybara's drag_to and Selenium's native click_and_hold,
    # but both simply fail to move the block ocassionally :/

    block_id = "#block_#{name}"
    to_id = "##{to['id']}"
    page.execute_script <<-SCRIPT
      var blockContent = jQuery('#{block_id}').remove();
      jQuery('#{to_id}').append(blockContent);
    SCRIPT

    # Expect to
    expect_block(to, name)
  end

  before do
    overview
    login_as(user)

    visit my_projects_overview_path(project)
  end

  it 'should provide block drag n drop' do
    # Test block positions
    MyProjectsOverview::DEFAULTS.each do |list, names|
      el = send(list)
      names.each { |name| expect_block(el, name) }
    end

    drag_to(:members, right, top)
    save_changes.click

    # scrolling so that the flash notice can be 'seen'
    wrapper = find('#wrapper')
    scroll_to_element(wrapper)
    expect(page).to have_selector('.flash.notice', text: I18n.t('js.notice_successful_update'))
    expect_block(top, :members)
    expect(page).to have_no_selector('#list-right #block_members')
  end

  it 'should add and remove fixed blocks' do
    # Expect existing blocks to be disabled
    MyProjectsOverview::DEFAULTS.each do |_, names|
      names.each { |name| expect(select).to have_selector("option[value=#{name}][disabled]") }
    end

    # Choosing the block disables the option
    select.find('option[value=calendar]').select_option
    expect(select).to have_selector("option[value=calendar][disabled]")

    # Moving once more
    drag_to(:calendar, hidden, left)
    save_changes.click

    expect(page).to have_selector('.flash.notice', text: I18n.t('js.notice_successful_update'))
    expect_block(left, :calendar)

    # Remove the block again
    find('#my-project-page-layout').click
    find('#block_calendar .remove-block').click
    expect(page).to have_no_selector('#list-left #block_calendar')

    save_changes.click

    expect(page).to have_selector('.flash.notice', text: I18n.t('js.notice_successful_update'))
    expect(page).to have_no_selector('#list-left #block_calendar')
  end

  it 'should allow to add and edit custom blocks' do
    select.find('option[value=custom_element]').select_option

    # edit form should be open
    find('#block_title_a').set 'My title'
    editor.click_and_type_slowly 'My **commonmark** content'
    find('#a-form-submit').click

    # expect changes to be saved
    expect(page).to have_selector('.widget-box--header', text: 'My title')

    custom_block = find_block(hidden, :a)

    expect(custom_block).to have_selector('.widget-box--header-title', text: 'My title')
    expect(custom_block).to have_selector('#a-text strong', text: 'commonmark')

    # edit form should be closed
    expect(custom_block).to have_no_selector('#block_title_a', visible: true)

    # Toggling the form works
    custom_block.find('.edit-textilizable').click
    expect(custom_block).to have_selector('#block_title_a', visible: true)
    custom_block.find('.textile-form .reset-textilizable').click
    expect(custom_block).to have_no_selector('#block_title_a', visible: true)

    # Moving to visible
    drag_to(:a, hidden, right)

    # Saving the block
    save_changes.click
    expect(page).to have_selector('.flash.notice', text: I18n.t('js.notice_successful_update'))
    expect_block(right, :a)

    # Go back to editing page
    find('#my-project-page-layout').click
    expect(page).to have_no_selector('#list-hidden #block_a')

    # Removing the block
    find('#block_a .remove-block').click
    page.driver.browser.switch_to.alert.accept
    save_changes.click

    expect(page).to have_selector('.flash.notice', text: I18n.t('js.notice_successful_update'))
    expect(page).to have_no_selector('#block_a')
  end

  describe 'macro elements' do
    let!(:work_package) { FactoryBot.create(:work_package, project: project) }

    let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
    let(:filters) { ::Components::WorkPackages::TableConfiguration::Filters.new }
    let(:columns) { ::Components::WorkPackages::Columns.new }

    it 'should allow to add and edit macros (Regression test #28399)' do
      select.find('option[value=custom_element]').select_option

      expect(page).to have_selector('.op-ckeditor--wrapper')
      expect(page).to have_selector('.ck-content')

      editor.in_editor do |_container, editable|
        editor.insert_macro 'Embed work package table'

        editor.set_markdown 'test'

        modal.expect_open
        modal.switch_to 'Filters'
        filters.expect_filter_count 1
        filters.add_filter_by('Type', 'is', work_package.type.name)

        modal.switch_to 'Columns'
        columns.assume_opened
        columns.uncheck_all save_changes: false
        columns.add 'ID', save_changes: false
        columns.add 'Subject', save_changes: false
        columns.add 'Type', save_changes: false
        columns.expect_checked 'ID'
        columns.expect_checked 'Subject'
        columns.expect_checked 'Type'

        # Save widget
        modal.save

        # Find widget, click to show toolbar
        expect(editable).to have_selector('.ck-widget.macro.-embedded-table')
      end

      # Save textile block
      find('#a-form-submit').click
      save_changes.click

      # Revisit page
      visit my_projects_overview_path(project)
      expect(page).to have_selector('#block_a')
      find('.edit-textilizable').click

      editor.in_editor do |_container, editable|
        # Find widget, click to show toolbar
        macro = editable.find('.ck-widget.macro.-embedded-table')
        macro.click

        # Edit widget again
        page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click

        modal.expect_open
        modal.switch_to 'Filters'
        filters.expect_filter_count 2
        modal.switch_to 'Columns'
        columns.assume_opened
        columns.expect_checked 'ID'
        columns.expect_checked 'Subject'
        columns.expect_checked 'Type'
        modal.cancel
      end

      find('#block_a .textile-form .reset-textilizable').click
    end
  end

  context 'as regular user' do
    let(:permissions) { %i(view_project) }
    let(:role) { FactoryBot.create :role, permissions: permissions }
    let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }

    it 'shows a 403 error' do
      expect(page).to have_selector('h2', text: '403')
      expect(page).to have_no_selector('.widget-box')
    end
  end
end
