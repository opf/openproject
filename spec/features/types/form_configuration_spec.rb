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

describe 'form configuration', type: :feature, js: true do
  let(:admin) { FactoryGirl.create :admin }
  let(:type) { FactoryGirl.create :type }

  let(:project) { FactoryGirl.create :project, types: [type] }
  let(:category) { FactoryGirl.create :category, project: project }
  let(:work_package) {
    FactoryGirl.create :work_package,
                       project: project,
                       type: type,
                       done_ratio: 10,
                       category: category
  }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:add_button) { page.find '.form-configuration--add-group' }
  let(:reset_button) { page.find '.form-configuration--reset' }
  let(:inactive_drop) { page.find '#type-form-conf-inactive-group .attributes' }

  def group_selector(name)
    ".type-form-conf-group[data-key='#{name}']"
  end

  def checkbox_selector(attribute)
    ".type-form-conf-attribute[data-key='#{attribute}'] .attribute-visibility input"
  end

  def attribute_selector(attribute)
    ".type-form-conf-attribute[data-key='#{attribute}']"
  end

  def find_group_handle(label)
    page.find("#{group_selector(label)} .group-handle")
  end

  def find_attribute_handle(attribute)
    page.find("#{attribute_selector(attribute)} .attribute-handle")
  end

  def set_visibility(attribute, checked:)
    attribute = page.find(attribute_selector(attribute))
    checkbox = attribute.find('input[type=checkbox]')
    checkbox.set checked
  end

  def expect_attribute(key:, checked: nil, translation: nil)
    attribute = page.find(attribute_selector(key))

    unless translation.nil?
      expect(attribute).to have_selector('.attribute-name', text: translation)
    end

    unless checked.nil?
      checkbox = attribute.find('input[type=checkbox]')
      expect(checkbox.checked?).to eq(checked)
    end
  end

  def move_to(attribute, group_label)
    handle = find_attribute_handle(attribute)
    group = find("#{group_selector(group_label)} .attributes")

    handle.drag_to group
    expect_group(group_label, key: attribute)
  end

  def add_group(name, expect: true)
    add_button.click
    input = find('.group-edit-in-place--input')
    input.set(name)
    input.send_keys(:return)

    expect_group(name) if expect
  end

  def rename_group(from, to)
    find('.group-name', text: from).click

    input = find('.group-edit-in-place--input')
    input.click
    input.set(to)
    input.send_keys(:return)

    expect(page).to have_selector('.group-name', text: to)
  end

  def expect_group(label, *attributes)
    expect(page).to have_selector("#{group_selector(label)} .group-name", text: label)

    within group_selector(label) do
      attributes.each do |attribute|
        expect_attribute(attribute)
      end
    end
  end

  def expect_inactive(attribute)
    expect(inactive_drop).to have_selector(".type-form-conf-attribute[data-key='#{attribute}']")
  end

  before do
    login_as(admin)
    visit edit_type_tab_path(id: type.id, tab: "form_configuration")
  end

  it 'resets the form properly after changes' do
    rename_group('Details', 'Whatever')
    set_visibility(:assignee, checked: true)
    expect_attribute(key: :assignee, checked: true)

    reset_button.click

    expect(page).to have_no_selector(group_selector('Whatever'))
    expect_group('Details')
    expect_attribute(key: :assignee, checked: false)
  end

  it 'detects errors for duplicate group names' do
    add_group('New Group')
    add_group('New Group', expect: false) # would fail since two selectors exist now

    expect(page).to have_selector("#{group_selector('New Group')}.-error", count: 1)
  end

  it 'allows modification of the form configuration' do
    #
    # Test default set of groups
    #
    expect_group 'People',
                 { key: :assignee, checked: false, translation: 'Assignee' },
                 { key: :responsible, checked: false, translation: 'Responsible' }

    expect_group 'Estimates and time',
                 { key: :estimated_time, checked: false, translation: 'Estimated time' },
                 { key: :spent_time, checked: false, translation: 'Spent time' }

    expect_group 'Details',
                 { key: :category, checked: false, translation: 'Category' },
                 { key: :date, checked: false, translation: 'Date' },
                 { key: :percentage_done, checked: false, translation: 'Progress (%)' },
                 { key: :version, checked: false, translation: 'Version' }


    #
    # Modify configuration
    #

    # Disable version
    find_attribute_handle(:version).drag_to inactive_drop
    expect_inactive(:version)

    # Toggle assignee to be always visible
    set_visibility(:assignee, checked: true)
    expect_attribute(key: :assignee, checked: true)

    # Rename group
    rename_group('Details', 'Whatever')
    rename_group('People', 'Cool Stuff')

    # Start renaming, but cancel
    find('.group-name', text: 'Cool Stuff').click
    input = find('.group-edit-in-place--input')
    input.set('FOOBAR')
    input.send_keys(:escape)
    expect(page).to have_selector('.group-name', text: 'Cool Stuff')
    expect(page).to have_no_selector('.group-name', text: 'FOOBAR')

    # Create new group
    add_group('New Group')
    move_to(:category, 'New Group')

    # Save configuration
    # click_button doesn't seem to work when the button is out of view!?
    page.execute_script('jQuery(".form-configuration--save").click()')
    expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

    # Expect configuration to be correct now
    expect_group 'Cool Stuff',
                 { key: :assignee, checked: true, translation: 'Assignee' },
                 { key: :responsible, checked: false, translation: 'Responsible' }

    expect_group 'Estimates and time',
                 { key: :estimated_time, checked: false, translation: 'Estimated time' },
                 { key: :spent_time, checked: false, translation: 'Spent time' }

    expect_group 'Whatever',
                 { key: :date, checked: false, translation: 'Date' },
                 { key: :percentage_done, checked: false, translation: 'Progress (%)' }

    expect_group 'New Group',
                 { key: :category, checked: false, translation: 'Category' }

    expect_inactive(:version)

    # Visit work package with that type
    wp_page.visit!
    wp_page.ensure_page_loaded

    # Category should be hidden
    wp_page.expect_hidden_field(:category)

    wp_page.expect_group('New Group') do
      wp_page.expect_attributes category: category.name
    end

    wp_page.expect_group('Whatever') do
      wp_page.expect_attributes percentageDone: '30'
    end

    wp_page.expect_group('Cool Stuff') do
      wp_page.expect_attributes assignee: '-'
    end

    # Empty attributes should be shown on toggle
    expected_attributes = ->() do
      wp_page.expect_hidden_field(:responsible)
      wp_page.expect_hidden_field(:estimated_time)
      wp_page.expect_hidden_field(:spent_time)
      wp_page.view_all_attributes

      wp_page.expect_group('Cool Stuff') do
        wp_page.expect_attributes responsible: '-'
      end

      wp_page.expect_group('Estimates and time') do
        wp_page.expect_attributes estimated_time: '-'
        wp_page.expect_attributes spent_time: '-'
      end
    end

    # Should match on edit view
    expected_attributes.call

    # New work package has the same configuration
    wp_page.click_create_wp_button(type)
    expected_attributes.call

    find('#work-packages--edit-actions-cancel').click
    expect(wp_page).not_to have_alert_dialog
    loading_indicator_saveguard
  end
end
