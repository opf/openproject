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

require 'features/support/components/ui_autocomplete'

module Components
  module WorkPackages
    class Relations
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::UIAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package)
        @work_package = work_package
      end

      def find_row(relatable)
        page.find(".relation-row-#{relatable.id}")
      end

      def click_relation(relatable)
        page.find(".relation-row-#{relatable.id} .wp-relations--subject-field").click
      end

      def edit_relation_type(relatable, to_type:)
        row = find_row(relatable)
        row.find('.relation-row--type').click

        expect(row).to have_selector('select.wp-inline-edit--field')
        row.find('.wp-inline-edit--field option', text: to_type).select_option
      end

      def hover_action(relatable, action)
        retry_block do
          # Focus type edit to expose buttons
          span = page.find(".relation-row-#{relatable.id} .relation-row--type", wait: 20)
          scroll_to_element(span)
          page.driver.browser.action.move_to(span.native).perform

          # Click the corresponding action button
          row = find_row(relatable)
          case action
          when :delete
            row.find('.relation-row--remove-btn').click
          when :info
            row.find('.wp-relations--description-btn').click
          end
        end
      end

      def remove_relation(relatable)
        ## Delete relation
        hover_action(relatable, :delete)

        # Expect relation to be gone
        expect_no_relation(relatable)
      end

      def add_relation(type:, to:)
        # Open create form
        find('#relation--add-relation').click

        # Select relation type
        container = find('.wp-relations-create--form', wait: 10)

        # Labels to expect
        relation_label = I18n.t('js.relation_labels.' + type)

        select relation_label, from: 'relation-type--select'

        # Enter the query and select the child
        autocomplete = container.find(".wp-relations--autocomplete")
        select_autocomplete autocomplete,
                            results_selector: '.wp-relations-autocomplete--results',
                            query: to.subject,
                            select_text: to.subject

        container.find('.wp-create-relation--save').click

        expect(page).to have_selector('.relation-group--header',
                                      text: relation_label.upcase,
                                      wait: 10)

        expect(page).to have_selector('.relation-row--type', text: to.type.name)

        expect(page).to have_selector('.wp-relations--subject-field', text: to.subject)

        ## Test if relation exist
        work_package.reload
        relation = work_package.relations.last
        expect(relation.label_for(work_package).to_s).to eq("label_#{type}")
        expect(relation.other_work_package(work_package).id).to eq(to.id)
      end

      def expect_relation(relatable)
        expect(relations_group).to have_selector('.wp-relations--subject-field', text: relatable.subject)
        end

      def expect_relation_by_text(text)
        expect(relations_group).to have_text('.wp-relations--subject-field', text)
      end

      def expect_no_relation(relatable)
        expect(page).to have_no_selector('.wp-relations--subject-field', text: relatable.subject)
      end

      def add_parent(query, work_package)
        # Open the parent edit
        find('.wp-relation--parent-change').click

        # Enter the query and select the child
        autocomplete = find(".wp-relations--autocomplete")
        select_autocomplete autocomplete,
                            query: query,
                            results_selector: '.wp-relations-autocomplete--results',
                            select_text: work_package.id
      end

      def expect_parent(work_package)
        expect(page).to have_selector '.wp-breadcrumb-parent',
                                      text: work_package.subject,
                                      wait: 10
      end

      def expect_no_parent
        expect(page).to have_no_selector '.wp-breadcrumb-parent', wait: 10
      end

      def remove_parent
        # Open the parent edit
        find('.wp-relation--parent-change').click

        # Submit empty autocomplete to remove
        autocomplete = find(".wp-relations--autocomplete")
        autocomplete.set ''
        autocomplete.send_keys :enter
      end

      def inline_create_child(subject_text)
        container = find('.wp-relations--children')
        scroll_to_and_click(container.find('.wp-inline-create-button-row .wp-inline-create--add-link'))

        subject = ::WorkPackageField.new(container, 'subject')
        subject.expect_active!
        subject.update subject_text
      end

      def openChildrenAutocompleter
        retry_block do
          find('.wp-inline-create--reference-link', text: I18n.t('js.relation_buttons.add_existing_child')).click

          # Security check to be sure that the autocompleter has finished loading
          page.find '.wp-relations-autocomplete--results'
        end
      end

      def add_existing_child(work_package)
        # Locate the create row container
        container = find('.wp-relations--add-form')

        # Enter the query and select the child
        autocomplete = container.find(".wp-relations--autocomplete")
        select_autocomplete autocomplete,
                            query: work_package.id,
                            results_selector: '.wp-relations-autocomplete--results',
                            select_text: work_package.subject

        container.find('.wp-create-relation--save').click
      end

      def expect_child(work_package)
        container = find('wp-relations-hierarchy wp-children-query')

        within container do
          expect(page)
            .to have_selector('.wp-table--cell-td.subject', text: work_package.subject, wait: 10)
        end
      end

      def expect_not_child(work_package)
        page.within('wp-relations-tab .work-packages-embedded-view--container') do
          row = ".wp-row-#{work_package.id}-table"

          expect(page).to have_no_selector(row)
        end
      end

      def children_table
        ::Pages::EmbeddedWorkPackagesTable.new find('wp-relations-tab .work-packages-embedded-view--container')
      end

      def relations_group
        find('wp-relations-tab wp-relations-group')
      end

      def remove_child(work_package)
        page.within('.work-packages-embedded-view--container') do
          row = ".wp-row-#{work_package.id}-table"

          find(row).hover
          find("#{row} .wp-table-action--unlink").click
        end
      end
    end
  end
end
