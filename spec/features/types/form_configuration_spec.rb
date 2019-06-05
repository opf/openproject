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

describe 'form configuration', type: :feature, js: true do
  let(:admin) { FactoryBot.create :admin }
  let(:type) { FactoryBot.create :type }

  let(:project) { FactoryBot.create :project, types: [type] }
  let(:category) { FactoryBot.create :category, project: project }
  let(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      done_ratio: 10,
                      category: category
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:form) { ::Components::Admin::TypeConfigurationForm.new }

  describe "with EE token" do
    before do
      with_enterprise_token(:edit_attribute_groups)
    end

    describe 'default configuration' do
      let(:dialog) { ::Components::ConfirmationDialog.new }
      before do
        login_as(admin)
        visit edit_type_tab_path(id: type.id, tab: "form_configuration")
      end

      it 'resets the form properly after changes' do
        form.rename_group('Details', 'Whatever')
        form.expect_attribute(key: :assignee)

        # Reset and cancel
        form.reset_button.click
        dialog.expect_open
        dialog.cancel

        expect(page).to have_selector('span.group-edit-handler', text: 'WHATEVER')

        # Click the dialog again after some time
        # Otherwise this may cause issues due to the animation,
        # which is why sleep is okay.
        sleep 1

        # Reset and confirm
        form.reset_button.click
        dialog.expect_open
        dialog.confirm

        # Wait for page reload
        sleep 1

        expect(page).to have_no_selector('.group-head', text: 'WHATEVER')
        form.expect_group('details', 'Details')
        form.expect_attribute(key: :assignee)
      end

      it 'detects errors for duplicate group names' do
        form.add_attribute_group('New Group')
        form.add_attribute_group('New Group', expect: false) # would fail since two selectors exist now

        form.save_changes

        expect(page).to have_selector(".type-form-conf-group.-error", count: 1)
      end

      it 'allows modification of the form configuration' do
        #
        # Test default set of groups
        #
        form.expect_group 'people',
                          'People',
                          key: :responsible, translation: 'Accountable'

        form.expect_group 'estimates_and_time',
                          'Estimates and time',
                          { key: :estimated_time, translation: 'Estimated time' },
                          { key: :spent_time, translation: 'Spent time' }

        form.expect_group 'details',
                          'Details',
                          { key: :category, translation: 'Category' },
                          { key: :date, translation: 'Date' },
                          { key: :percentage_done, translation: 'Progress (%)' },
                          { key: :priority, translation: 'Priority' },
                          { key: :version, translation: 'Version' }

        #
        # Modify configuration
        #

        # Disable version
        form.drag_and_drop(form.find_attribute_handle(:version), form.inactive_group)
        form.expect_inactive(:version)

        # Rename group
        form.rename_group('Details', 'Whatever')
        form.rename_group('People', 'Cool Stuff')

        # Start renaming, but cancel
        find('.group-edit-handler', text: 'COOL STUFF').click
        input = find('.group-edit-in-place--input')
        input.set('FOOBAR')
        input.send_keys(:escape)
        expect(page).to have_selector('.group-edit-handler', text: 'COOL STUFF')
        expect(page).to have_no_selector('.group-edit-handler', text: 'FOOBAR')

        # Create new group
        form.add_attribute_group('New Group')
        form.move_to(:category, 'New Group')

        # Delete attribute from group
        form.remove_attribute('assignee')

        # Save configuration
        form.save_changes
        expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)

        # Expect configuration to be correct now
        form.expect_no_attribute('assignee', 'Cool Stuff')

        form.expect_group 'Cool Stuff',
                          'Cool Stuff',
                          { key: :responsible, translation: 'Accountable' }

        form.expect_group 'estimates_and_time',
                          'Estimates and time',
                          { key: :estimated_time, translation: 'Estimated time' },
                          { key: :spent_time, translation: 'Spent time' }

        form.expect_group 'Whatever',
                          'Whatever',
                          { key: :date, translation: 'Date' },
                          { key: :percentage_done, translation: 'Progress (%)' }

        form.expect_group 'New Group',
                          'New Group',
                          { key: :category, translation: 'Category' }

        form.expect_inactive(:version)

        # Test the actual type backend
        type.reload
        expect(type.attribute_groups.map { |el| el.key })
          .to include('Cool Stuff', :estimates_and_time, 'Whatever', 'New Group')

        # Visit work package with that type
        wp_page.visit!
        wp_page.ensure_page_loaded

        # Version should be hidden
        wp_page.expect_hidden_field(:version)

        wp_page.expect_group('New Group') do
          wp_page.expect_attributes category: category.name
        end

        wp_page.expect_group('Whatever') do
          wp_page.expect_attributes percentageDone: '10'
        end

        wp_page.expect_group('Cool Stuff') do
          wp_page.expect_attributes responsible: '-'
        end

        # Empty attributes should be shown on toggle
        wp_page.expect_hidden_field(:assignee)
        wp_page.expect_hidden_field(:spent_time)

        wp_page.expect_group('Estimates and time') do
          wp_page.expect_attributes estimated_time: '-'
          wp_page.expect_attributes spent_time: '-'
        end

        # New work package has the same configuration
        wp_page.expect_hidden_field(:assignee)
        wp_page.expect_hidden_field(:spent_time)
        wp_page.click_create_wp_button(type)

        wp_page.expect_group('Estimates and time') do
          expect(page).to have_selector('.wp-edit-field.estimatedTime')
        end

        find('#work-packages--edit-actions-cancel').click
        expect(wp_page).not_to have_alert_dialog
        loading_indicator_saveguard
      end
    end

    describe 'required custom field' do
      let(:custom_fields) { [custom_field] }
      let(:custom_field) { FactoryBot.create(:integer_issue_custom_field, is_required: true, name: 'MyNumber') }
      let(:cf_identifier) { "custom_field_#{custom_field.id}" }
      let(:cf_identifier_api) { "customField#{custom_field.id}" }

      before do
        project
        custom_field

        login_as(admin)
        visit edit_type_tab_path(id: type.id, tab: "form_configuration")
      end

      it 'shows the field' do
        # Should be initially disabled
        form.expect_inactive(cf_identifier)

        # Add into new group
        form.add_attribute_group('New Group')
        form.move_to(cf_identifier, 'New Group')
        form.expect_attribute(key: cf_identifier)

        form.save_changes
        expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)
      end
    end

    describe 'custom fields' do
      let(:project_settings_page) { Pages::Projects::Settings.new(project) }

      let(:custom_fields) { [custom_field] }
      let(:custom_field) { FactoryBot.create(:integer_issue_custom_field, name: 'MyNumber') }
      let(:cf_identifier) { "custom_field_#{custom_field.id}" }
      let(:cf_identifier_api) { "customField#{custom_field.id}" }

      before do
        project
        custom_field

        login_as(admin)
        visit edit_type_tab_path(id: type.id, tab: "form_configuration")

        # Should be initially disabled
        form.expect_inactive(cf_identifier)

        # Add into new group
        form.add_attribute_group('New Group')
        form.move_to(cf_identifier, 'New Group')

        # Make visible
        form.expect_attribute(key: cf_identifier)

        form.save_changes
        expect(page).to have_selector('.flash.notice', text: 'Successful update.', wait: 10)
      end

      context 'inactive in project' do
        it 'can be added to the type, but is not shown' do
          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # CF should be hidden
          wp_page.expect_no_group('New Group')
          wp_page.expect_attribute_hidden(cf_identifier_api)

          # Enable in project, should then be visible
          project_settings_page.visit_tab!('custom_fields')
          expect(page).to have_selector(".custom-field-#{custom_field.id} td", text: 'MyNumber')
          expect(page).to have_selector(".custom-field-#{custom_field.id} td", text: type.name)

          id_checkbox = find("#project_work_package_custom_field_ids_#{custom_field.id}")
          expect(id_checkbox).to_not be_checked
          id_checkbox.set(true)

          click_button 'Save'

          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # Category should be hidden
          wp_page.expect_group('New Group') do
            wp_page.expect_attributes cf_identifier_api => '-'
          end
        end
      end

      context 'active in project' do
        let(:project) do
          FactoryBot.create :project,
                            types: [type],
                            work_package_custom_fields: custom_fields
        end

        it 'can be added to type and is visible' do
          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # Category should be hidden
          wp_page.expect_group('New Group') do
            wp_page.expect_attributes cf_identifier_api => '-'
          end

          # Ensure CF is checked
          project_settings_page.visit_tab!('custom_fields')
          expect(page).to have_selector(".custom-field-#{custom_field.id} td", text: 'MyNumber')
          expect(page).to have_selector(".custom-field-#{custom_field.id} td", text: type.name)
          expect(page).to have_selector("#project_work_package_custom_field_ids_#{custom_field.id}[checked]")
        end
      end
    end
  end

  describe "without EE token" do
    let(:dialog) { ::Components::ConfirmationDialog.new }

    it "should disable adding and renaming groups" do
      with_enterprise_token(nil)
      login_as(admin)
      visit edit_type_tab_path(id: type.id, tab: "form_configuration")

      find('.group-edit-handler', text: "DETAILS").click
      dialog.expect_open
    end
  end
end
