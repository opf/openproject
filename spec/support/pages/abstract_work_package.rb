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

require 'support/pages/page'

module Pages
  class AbstractWorkPackage < Page
    attr_reader :work_package, :type_field_selector, :subject_field_selector

    def initialize(work_package)
      @work_package = work_package

      @type_field_selector = '.wp-edit-field.type'
      @subject_field_selector = '.wp-edit-field.subject'
    end

    def visit_tab!(tab)
      visit path(tab)
    end

    def expect_tab(tab)
      within(container) do
        expect(page).to have_selector('.tabrow li.selected', text: tab.to_s.camelize)
      end
    end

    def edit_field(attribute, context)
      WorkPackageField.new(context, attribute)
    end

    def expect_subject
      within(container) do
        expect(page).to have_content(work_package.subject)
      end
    end

    def ensure_page_loaded
      tries = 0
      begin
        find('.work-package-details-activities-activity-contents .user',
             text: work_package.journals.last.user.name,
             wait: 10)
      rescue => e
        # HACK This error may happen since activities are loaded several times
        # in the old resource, and may cause a reload.
        tries += 1
        retry unless tries > 5
      end
    end

    def expect_attributes(attribute_expectations)
      attribute_expectations.each do |label_name, value|
        label = label_name.to_s

        expect(page).to have_selector(".wp-edit-field.#{label.camelize(:lower)}", text: value)
      end
    end

    def expect_attribute_hidden(label)
      expect(page).not_to have_selector(".wp-edit-field.#{label.downcase}")
    end

    def expect_activity(user, number: nil)
      container = '#work-package-activites-container'
      container += " #activity-#{number}" if number

      expect(page).to have_selector(container + ' .user', text: user.name)
    end

    def expect_parent(parent = nil)
      parent ||= work_package.parent

      expect(parent).to_not be_nil

      visit_tab!('relations')

      expect(page).to have_selector('.relation.parent .work_package',
                                    text: "##{parent.id} #{parent.type.name}: #{parent.subject}")
    end

    def update_attributes(key_value_map)
      set_attributes(key_value_map)
    end

    def set_attributes(key_value_map)
      key_value_map.each_with_index.map do |(key, value), index|
        field = work_package_field key
        field.activate_edition

        field.set_value value
        field.save!

        unless index == key_value_map.length - 1
          ensure_no_conflicting_modifications
        end
      end
    end

    def work_package_field(key)
      if key =~ /customField(\d+)$/
        cf = CustomField.find $1

        if cf.field_format == 'text'
          WorkPackageTextAreaField.new page, key
        else
          WorkPackageField.new page, key
        end
      else
        WorkPackageField.new page, key
      end
    end

    def add_child
      visit_tab!('relations')

      page.find('.relation a', text: I18n.t('js.relation_labels.children')).click

      click_button I18n.t('js.relation_buttons.add_child')

      create_page(parent_work_package: work_package)
    end

    def visit_copy!
      page = create_page(original_work_package: work_package)
      page.visit!

      page
    end

    def view_all_attributes
      # click_link does not work for reasons(TM)

      page.find('a', text: I18n.t('js.label_show_attributes')).click
    end

    def trigger_edit_mode
      page.click_button(I18n.t('js.button_edit'))
    end

    def trigger_edit_comment
      add_comment_container.find('.inplace-editing--trigger-link').click
    end

    def update_comment(comment)
      add_comment_container.fill_in 'inplace-edit--write-value--activity', with: comment
    end

    def preview_comment
      label = I18n.t('js.inplace.btn_preview_enable')
      add_comment_container
        .find(:xpath, "//button[@title='#{label}']")
        .click
    end

    def save_comment
      label = I18n.t('js.label_add_comment')
      add_comment_container.find(:xpath, "//a[@title='#{label}']").click
    end

    def save!
      page.click_button(I18n.t('js.button_save'))
    end

    def add_comment_container
      find('.work-packages--activity--add-comment')
    end

    def click_add_wp_button
      find('.add-work-package:not([disabled])', text: 'Work package').click
    end

    def select_type(type)
      find(@type_field_selector + ' option', text: type).select_option
    end

    def subject_field
      expect(page).to have_selector(@subject_field_selector + ' input', wait: 10)
      find(@subject_field_selector + ' input')
    end

    def description_field
      find('.wp-edit-field.description textarea')
    end

    private

    def create_page(_args)
      raise NotImplementedError
    end

    def ensure_no_conflicting_modifications
      expect_notification(message: 'Successful update')
      dismiss_notification!
      expect_no_notification(message: 'Successful update')
    end
  end
end
