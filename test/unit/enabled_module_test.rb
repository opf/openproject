# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class EnabledModuleTest < ActiveSupport::TestCase
  fixtures :projects, :wikis
  
  def test_enabling_wiki_should_create_a_wiki
    CustomField.delete_all
    project = Project.create!(:name => 'Project with wiki', :identifier => 'wikiproject')
    assert_nil project.wiki
    project.enabled_module_names = ['wiki']
    project.reload
    assert_not_nil project.wiki
    assert_equal 'Wiki', project.wiki.start_page
  end
  
  def test_reenabling_wiki_should_not_create_another_wiki
    project = Project.find(1)
    assert_not_nil project.wiki
    project.enabled_module_names = []
    project.reload
    assert_no_difference 'Wiki.count' do
      project.enabled_module_names = ['wiki']
    end
    assert_not_nil project.wiki
  end
end
