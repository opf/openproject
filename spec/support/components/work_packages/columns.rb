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

module Components
  module WorkPackages
    class Columns
      include Capybara::DSL
      include RSpec::Matchers

      attr_reader :impaired

      def initialize(impaired: false)
        @impaired = impaired
      end

      def expect_column_not_available(name)
        modal_open? or open_modal

        if impaired
          within_modal do
            expect(page)
              .to have_no_selector('.form--check-box-container', text: name)
          end
        else
          # Open select2
          find('.columns-modal--content .select2-input').click
          expect(page).to have_no_selector('.select2-result-label', text: name)
          find('.columns-modal--content .select2-input').send_keys :escape
        end
      end

      def expect_column_not_selectable(name)
        modal_open? or open_modal

        if impaired
          expect_checked name
        else
          # Open select2
          find('.columns-modal--content .select2-input').click
          expect(page).to have_no_selector('.select2-result-label', text: name)
          find('.columns-modal--content .select2-input').send_keys :escape
        end
      end

      def expect_column_available(name)
        modal_open? or open_modal

        if impaired
          within_modal do
            expect(page)
              .to have_selector('.form--label-with-check-box', text: name)
          end
        else
          # Open select2
          find('.columns-modal--content .select2-input').click
          expect(page).to have_selector('.select2-result-label', text: name)
          find('.columns-modal--content .select2-input').send_keys :escape
        end
      end

      def add(name, save_changes: true)
        modal_open? or open_modal

        if impaired
          within_modal do
            input = find "input[type=checkbox][title='#{name}'"
            input.set true
          end
        else
          find('.columns-modal--content .select2-input').click
          find('.select2-results .select2-result-label', text: name).click
        end

        apply if save_changes
      end

      def remove(name, save_changes: true)
        modal_open? or open_modal

        within_modal do
          if impaired
            input = find "input[type=checkbox][title='#{name}']"
            input.set false
          else
            container = find('.select2-search-choice', text: name)
            container.find('.select2-search-choice-close').click
          end
        end

        apply if save_changes
      end

      def expect_checked(name)
        within_modal do
          if impaired
            checkbox = find("input[type=checkbox][title='#{name}']")
            expect(checkbox).to be_checked
          else
            expect(page).to have_selector('.select2-search-choice', text: name)
          end
        end
      end

      def uncheck_all(save_changes: true)
        modal_open? or open_modal

        within_modal do
          if impaired
            expect(page).to have_selector('input[type=checkbox][title="Subject"]')
            page.all("input[type=checkbox]").each { |input| input.set false }
          else
            expect(page).to have_selector('.select2-search-choice', minimum: 1)
            page.all('.select2-search-choice-close').each do |el|
              el.click
              sleep 1
            end
          end
        end

        apply if save_changes
      end


      def apply
        @opened = false

        click_button('Apply')
      end

      def open_modal
        @opened = true
        ::Components::WorkPackages::TableConfigurationModal.new.open_and_switch_to 'Columns'
      end

      def assume_opened
        @opened = true
      end

      private

      def within_modal
        page.within('.wp-table--configuration-modal') do
          yield
        end
      end

      def modal_open?
        !!@opened
      end
    end
  end
end
