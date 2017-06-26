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

      def hover_action(relatable, action)
        retry_block do
          # Focus type edit to expose buttons
          span = page.find(".relation-row-#{relatable.id} .relation-row--type")
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
        select_autocomplete(autocomplete, query: to.subject, select_text: to.subject)

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

      def expect_no_relation(relatable)
        expect(page).to have_no_selector('.wp-relations--subject-field', text: relatable.subject)
      end
    end
  end
end
