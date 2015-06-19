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
require 'features/work_packages/work_packages_page'

describe 'Select work package row', type: :feature do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package_1) {
    FactoryGirl.create(:work_package,
                       project: project)
  }
  let(:work_package_2) {
    FactoryGirl.create(:work_package,
                       project: project)
  }
  let(:work_package_3) {
    FactoryGirl.create(:work_package,
                       project: project)
  }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  include_context 'work package table helpers'

  before do
    allow(User).to receive(:current).and_return(user)

    work_package_1
    work_package_2
    work_package_3

    work_packages_page.visit_index
  end

  describe 'Work package row selection', js: true do
    def select_work_package_row(number, mouse_button_behavior = :left)
      element = find(".workpackages-table tr:nth-of-type(#{number}).issue td.id")
      case mouse_button_behavior
      when :double
        element.double_click
      when :right
        element.right_click
      else
        element.click
      end
    end

    def select_work_package_row_with_shift(number)
      element = find(".workpackages-table tr:nth-of-type(#{number}).issue td.id")
      page.driver.browser.action.key_down(:shift)
        .click(element.native)
        .key_up(:shift)
        .perform
    end

    def select_work_package_row_with_ctrl(number)
      element = find(".workpackages-table tr:nth-of-type(#{number}).issue td.id")
      page.driver.browser.action.key_down(:control)
        .click(element.native)
        .key_up(:control)
        .perform
    end

    def check_row_selection_state(row_index, state = true)
      selector = ".workpackages-table tr:nth-of-type(#{row_index}).issue input[type=checkbox]:checked"

      expect(page).to (state ? have_selector(selector) : have_no_selector(selector))
    end

    shared_examples_for 'work package row selected' do
      let(:indices) { Array(index) }

      it do
        Capybara.default_selector = :css

        indices.each do |i|
          check_row_selection_state(i)
        end
      end
    end

    shared_examples_for 'work package row not selected' do
      let(:indices) { Array(index) }

      it do
        Capybara.default_selector = :css

        indices.each do |i|
          check_row_selection_state(i, false)
        end
      end
    end

    shared_examples_for 'right click preserves selection' do
      before { select_work_package_row(selected_rows.first, :right) }

      it_behaves_like 'work package row selected' do
        let(:index) { selected_rows }
      end

      it_behaves_like 'work package row not selected' do
        let(:index) { unselected_rows }
      end
    end

    describe 'single selection' do
      shared_examples_for 'single select' do
        before { select_work_package_row(1, mouse_button) }

        it_behaves_like 'work package row selected' do
          let(:index) { 1 }
        end

        context 'select a different row' do
          before do
            check_row_selection_state(1)
            select_work_package_row(2, mouse_button)
          end

          it_behaves_like 'work package row selected' do
            let(:index) { 2 }
          end

          it_behaves_like 'work package row not selected' do
            let(:index) { 1 }
          end
        end
      end

      shared_examples_for 'double select unselects' do
        context 'clicking selected row again' do
          before do
            select_work_package_row(1, mouse_button)
            check_row_selection_state(1)
            select_work_package_row(1, mouse_button)
          end

          it_behaves_like 'work package row not selected' do
            let(:index) { 1 }
          end
        end
      end

      it_behaves_like 'single select' do
        let(:mouse_button) { :left }
      end

      it_behaves_like 'double select unselects' do
        let(:mouse_button) { :left }
      end

      it_behaves_like 'single select' do
        let(:mouse_button) { :right }
      end
    end

    describe 'range selection' do
      context 'first row selected' do
        before { select_work_package_row_with_shift(1) }

        it_behaves_like 'work package row selected' do
          let(:index) { 1 }
        end

        context 'select following row' do
          before do
            check_row_selection_state(1)
            select_work_package_row_with_shift(2)
          end

          it_behaves_like 'work package row selected' do
            let(:index) { [1, 2] }
          end

          context 'uninvolved row' do
            before { check_row_selection_state(2) }

            it_behaves_like 'work package row not selected' do
              let(:index) { 3 }
            end

            it_behaves_like 'right click preserves selection' do
              let(:selected_rows) { [1, 2] }
              let(:unselected_rows) { 3 }
            end
          end
        end

        context 'select first after next row' do
          before do
            check_row_selection_state(1)
            select_work_package_row_with_shift(3)
          end

          it_behaves_like 'work package row selected' do
            let(:index) { [1, 2, 3] }
          end

          context 'select row after first selected row' do
            before do
              check_row_selection_state(2)
              check_row_selection_state(3)

              select_work_package_row_with_shift(2)

              check_row_selection_state(3, false)
            end

            it_behaves_like 'work package row selected' do
              let(:index) { [1, 2] }
            end

            it_behaves_like 'work package row not selected' do
              let(:index) { 3 }
            end
          end
        end
      end

      context 'swapping' do
        before { select_work_package_row(2) }

        it_behaves_like 'work package row selected' do
          let(:index) { 2 }
        end

        context 'select predecessor' do
          before do
            check_row_selection_state(2)
            select_work_package_row_with_shift(1)
          end

          it_behaves_like 'work package row selected' do
            let(:index) { [1, 2] }
          end

          context 'select successor' do
            before do
              check_row_selection_state(1)
              select_work_package_row_with_shift(3)
            end

            it_behaves_like 'work package row selected' do
              let(:index) { [2, 3] }
            end

            it_behaves_like 'work package row not selected' do
              let(:index) { 1 }
            end
          end
        end
      end
    end

    describe 'specific selection' do
      before { select_work_package_row_with_ctrl(1) }

      it_behaves_like 'work package row selected' do
        # apparently it should be selected if there one row only
        let(:index) { 1 }
      end

      context 'select first after next row' do
        before do
          check_row_selection_state(1)
          select_work_package_row_with_ctrl(3)
        end

        it_behaves_like 'work package row selected' do
          let(:index) { [1, 3] }
        end

        context 'uninvolved row' do
          before { check_row_selection_state(3) }

          it_behaves_like 'work package row not selected' do
            let(:index) { 2 }
          end

          it_behaves_like 'right click preserves selection' do
            let(:selected_rows) { [1, 3] }
            let(:unselected_rows) { 2 }
          end
        end
      end
    end

    describe 'opening work package details' do
      before do
        select_work_package_row(1, :double)
      end

      it_behaves_like 'work package row selected' do
        let(:index) { 1 }
      end
    end
  end
end
