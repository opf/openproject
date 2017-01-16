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

require 'spec_helper'

describe Wiki, type: :model do

  describe 'creation' do
    let(:project) { FactoryGirl.create(:project, disable_modules: 'wiki') }
    let(:start_page) { 'The wiki start page' }

    it_behaves_like 'acts_as_watchable included' do
      let(:model_instance) { FactoryGirl.create(:wiki) }
      let(:watch_permission) { :view_wiki_pages }
      let(:project) { model_instance.project }
    end

    describe '#create' do
      let(:wiki) { project.create_wiki start_page: start_page }

      it 'creates a wiki menu item on creation' do
        expect(wiki.wiki_menu_items).to be_one
      end

      it 'sets the wiki menu item title to the name of the start page' do
        expect(wiki.wiki_menu_items.first.title).to eq(start_page)
      end
    end
  end
end
