#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe WikiMenuItem do
  before(:each) do
    @project = FactoryGirl.create(:project, :enabled_module_names => %w[activity])
    @current = FactoryGirl.create(:user, :login => "user1", :mail => "user1@users.com")

    User.stub(:current).and_return(@current)
  end

  it 'should create a default wiki menu item when enabling the wiki' do
    WikiMenuItem.all.should_not be_any

    @project.enabled_modules << EnabledModule.new(:name => 'wiki')
    @project.reload

    wiki_item = @project.wiki.wiki_menu_items.first
    wiki_item.name.should eql 'Wiki'
    wiki_item.title.should eql 'Wiki'
    wiki_item.options[:index_page].should eql true
    wiki_item.options[:new_wiki_page].should eql true
  end

  it 'should change title when a wikipage is renamed' do
    wikipage = FactoryGirl.create(:wiki_page, :title => 'Oldtitle')

    menu_item_1 = FactoryGirl.create(:wiki_menu_item, :wiki_id => wikipage.wiki.id,
                                 :name    => 'Item 1',
                                 :title   => 'Oldtitle')

    wikipage.title = 'Newtitle'
    wikipage.save!

    menu_item_1.reload
    menu_item_1.title.should == wikipage.title
  end

  describe 'it should destroy' do
    before(:each) do
      @project.enabled_modules << EnabledModule.new(:name => 'wiki')
      @project.reload

      @menu_item_1 = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                    :name    => 'Item 1',
                                    :title   => 'Item 1')

      @menu_item_2 = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                    :name    => 'Item 2',
                                    :parent_id    => @menu_item_1.id,
                                    :title   => 'Item 2')
    end

    it 'all children when deleting the parent' do
      @menu_item_1.destroy

      expect {WikiMenuItem.find(@menu_item_1.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {WikiMenuItem.find(@menu_item_2.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'all items when destroying' do
      it 'the associated project' do
        @project.destroy
        WikiMenuItem.all.should_not be_any
      end

      it 'the associated wiki' do
        @project.wiki.destroy
        WikiMenuItem.all.should_not be_any
      end
    end
  end
end
