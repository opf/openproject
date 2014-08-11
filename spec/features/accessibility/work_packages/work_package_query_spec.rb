#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe 'Work package index accessibility', :type => :feature do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let!(:work_package) { FactoryGirl.create(:work_package,
                                           project: project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:sort_ascending_selector) { '.icon-sort-ascending' }
  let(:sort_descending_selector) { '.icon-sort-descending' }

  before do
    allow(User).to receive(:current).and_return(user)

    work_packages_page.visit_index
  end

  describe 'Select all link' do
    def select_all_link
      find('table.workpackages-table th.checkbox a')
    end

    describe 'Initial state', js: true do
      it { expect(select_all_link).not_to be_nil }

      it { expect(select_all_link[:title]).to eq(I18n.t(:button_check_all)) }

      it { expect(select_all_link[:alt]).to eq(I18n.t(:button_check_all)) }

      it do
        expect(select_all_link).to have_selector('.hidden-for-sighted',
                                                 :visible => false,
                                                 :text => I18n.t(:button_check_all))
      end
    end

    describe 'Change state', js: true do
      # TODO
    end

    after do
      # Ensure that all requests have fired and are answered.  Otherwise one
      # spec can interfere with the next when a request of the former is still
      # running in the one process but the other process has already removed
      # the data in the db to prepare for the next spec.
      #
      # Taking an element, that get's activated late in the page setup.
      expect(page).not_to have_selector('ul.dropdown-menu a.inactive',
                                    :text => Regexp.new("^#{I18n.t(:button_save)}$"),
                                    :visible => false)
    end
  end

  describe 'Sort link', js: true do
    def column_header_link
      find(column_header_link_selector)
    end

    def click_sort_ascending_link
      execute_script "jQuery('#{sort_ascending_selector}').click()"
    end

    def click_sort_descending_link
      execute_script "jQuery('#{sort_descending_selector}').click()"
    end

    shared_examples_for 'sort column' do
      def column_header
        find(column_header_selector)
      end

      it do
        expect(column_header).not_to be_nil
        expect(column_header.find("span.sort-header")[:title]).to eq(sort_text)
      end
    end

    shared_examples_for 'unsorted column' do
      let(:sort_text) { I18n.t(:label_open_menu) }

      it_behaves_like 'sort column'
    end

    shared_examples_for 'ascending sorted column' do
      let(:sort_text) { "#{I18n.t(:label_ascending)} #{I18n.t(:label_sorted_by, value: "\"#{link_caption}\"")}" }

      it_behaves_like 'sort column'
    end

    shared_examples_for 'descending sorted column' do
      let(:sort_text) { "#{I18n.t(:label_descending)} #{I18n.t(:label_sorted_by, value: "\"#{link_caption}\"")}" }

      it_behaves_like 'sort column'
    end

    shared_examples_for 'sortable column' do
      describe 'Initial sort' do
        it_behaves_like 'unsorted column'
      end

      describe 'descending' do
        before do
          column_header_link.click
          click_sort_descending_link
        end

        it_behaves_like 'descending sorted column'
      end

      describe 'ascending' do
        before do
          column_header_link.click
          click_sort_ascending_link
        end

        it_behaves_like 'ascending sorted column'
      end
    end

    describe 'id column' do
      let(:link_caption) { '#' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end

    describe 'type column' do
      let(:link_caption) { 'Type' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end

    describe 'status column' do
      let(:link_caption) { 'Status' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th + th + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end

    describe 'priority column' do
      let(:link_caption) { 'Priority' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th + th + th + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end

    describe 'subject column' do
      let(:link_caption) { 'Subject' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th + th + th + th + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end

    describe 'assigned to column' do
      let(:link_caption) { 'Assignee' }
      let(:column_header_selector) { 'table.workpackages-table th.checkbox + th + th + th + th + th + th' }
      let(:column_header_link_selector) { column_header_selector + ' a' }

      it_behaves_like 'sortable column'
    end
  end
end
