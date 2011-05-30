#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
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
