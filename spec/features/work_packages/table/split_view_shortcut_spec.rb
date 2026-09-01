# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

require 'spec_helper'

describe 'Split view shortcut', js: true do
  let(:user) { create(:admin) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

  before do
    login_as(user)
  end

  shared_examples 'close split view' do |keyToBePressed|
    describe 'when key is pressed' do
      let!(:work_package) { create(:work_package) }
      let!(:wp_table) { Pages::WorkPackagesTable.new }

      before do
        wp_table.visit!
      end

      it 'closes the split view' do
        view = wp_table.open_split_view work_package
        find('body').send_keys keyToBePressed
        view.expect_closed
      end
    end
  end

  describe 'closing split view with lower case i' do
    it_behaves_like 'close split view', 'i'
  end

  describe 'closing split view with upper case I' do
    it_behaves_like 'close split view', 'I'
  end


  shared_examples 'open split view' do |keyToBePressed|
    describe 'when key is pressed' do
      let!(:work_package) { create(:work_package) }
      let!(:wp_table) { Pages::WorkPackagesTable.new }
      let(:split_view) { Pages::SplitWorkPackage.new(work_package) }
      
      before do
        wp_table.visit!
      end

      it 'opens the split view' do
        find('body').send_keys keyToBePressed
        split_view.expect_open
      end
    end
  end

  describe 'opening split view with lower case i' do
    it_behaves_like 'open split view', 'i'
  end

  describe 'opening split view with upper case I' do
    it_behaves_like 'open split view', 'I'
  end
end
