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

describe 'Work package index accessibility' do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let!(:work_package) { FactoryGirl.create(:work_package,
                                           project: project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    allow(User).to receive(:current).and_return(user)

    work_packages_page.visit_index
  end

  describe 'Select all link' do
    let(:select_all_link) { find('table.list.issues th.checkbox a') }
    let(:description_for_blind) { select_all_link.find('span.hidden-for-sighted') }

    describe 'Initial state' do
      it { expect(select_all_link).not_to be_nil }

      it { expect(select_all_link[:title]).to eq(I18n.t(:button_check_all)) }

      it { expect(select_all_link[:alt]).to eq(I18n.t(:button_check_all)) }

      it { expect(description_for_blind.text).to eq(I18n.t(:button_check_all)) }
    end

    describe 'Change state', js: true do
      # TODO
    end
  end

  describe 'Sort link' do
    shared_examples_for 'sort column' do
      it { expect(find(sort_header_selector)[:title]).to eq(sort_text) }
    end

    shared_examples_for 'unsorted column' do
      let(:sort_text) { I18n.t(:label_sort_by, value: "\"#{link_caption}\"") }

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

    shared_examples_for 'descending sortable first' do
      describe 'one click' do
        before { find(sort_link_selector).click }

        it_behaves_like 'descending sorted column'

        describe 'two clicks' do
          before { find(sort_link_selector).click }

          it_behaves_like 'ascending sorted column'
        end
      end
    end

    shared_examples_for 'ascending sortable first' do
      describe 'one click' do
        before { find(sort_link_selector).click }

        it_behaves_like 'ascending sorted column'

        describe 'two clicks' do
          before { find(sort_link_selector).click }

          it_behaves_like 'descending sorted column'
        end
      end
    end

    shared_examples_for 'sortable column' do
      describe 'Initial sort' do
        it_behaves_like 'unsorted column'
      end
    end

    describe 'id column' do
      let(:link_caption) { '#' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'descending sortable first'
    end

    describe 'type column' do
      let(:link_caption) { 'Type' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'ascending sortable first'
    end

    describe 'status column' do
      let(:link_caption) { 'Status' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th + th + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'ascending sortable first'
    end

    describe 'priority column' do
      let(:link_caption) { 'Priority' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th + th + th + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'descending sortable first'
    end

    describe 'subject column' do
      let(:link_caption) { 'Subject' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th + th + th + th + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'ascending sortable first'
    end

    describe 'assigned to column' do
      let(:link_caption) { 'Assignee' }
      let(:sort_header_selector) { 'table.list.issues th.checkbox + th + th + th + th + th + th' }
      let(:sort_link_selector) { sort_header_selector + ' a' }

      it_behaves_like 'sortable column'

      it_behaves_like 'ascending sortable first'
    end
  end
end
