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
require 'features/page_objects/notification'
require 'features/work_packages/shared_contexts'
require 'features/work_packages/work_packages_page'

feature 'Wiki menu items' do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project, enabled_module_names: %w[wiki] }
  let(:wiki) { project.wiki }
  let(:parent_menu) { wiki.wiki_menu_items.find_by(name: 'wiki') }

  before do
    allow(User).to receive(:current).and_return user
  end

  context 'with identical names' do
    # Create two items with identical slugs (one with space, which is removed)
    let(:item1) do
      MenuItems::WikiMenuItem.new(navigatable_id: wiki.id,
                                  parent: parent_menu, title: 'Item 1', name: 'slug')
    end
    let(:item2) do
      MenuItems::WikiMenuItem.new(navigatable_id: wiki.id,
                                  parent: parent_menu, title: 'Item 2', name: 'slug ')
    end

    it 'one is invalid and deleted during visit' do
      expect(wiki.wiki_menu_items.count).to eq(1)

      item1.save!
      item2.save!
      wiki.wiki_menu_items.reload
      expect(wiki.wiki_menu_items.count).to eq(3)

      visit project_wiki_path(project, project.wiki)

      wiki.wiki_menu_items.reload
      expect(wiki.wiki_menu_items.count).to eq(2)
      expect(wiki.wiki_menu_items.pluck(:name).sort).to eq(%w(slug wiki))
    end
  end
end
