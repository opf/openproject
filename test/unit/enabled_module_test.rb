#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class EnabledModuleTest < ActiveSupport::TestCase
  def test_enabling_wiki_should_create_a_wiki
    CustomField.delete_all
    FactoryGirl.create(:type_standard)
    project = Project.create!(:name => 'Project with wiki', :identifier => 'wikiproject')
    assert_nil project.wiki
    project.enabled_module_names = ['wiki']
    wiki = FactoryGirl.create :wiki, :project => project
    project.reload
    assert_not_nil project.wiki
    assert_equal 'Wiki', project.wiki.start_page
  end

  def test_reenabling_wiki_should_not_create_another_wiki
    project = FactoryGirl.create :project
    wiki = FactoryGirl.create :wiki, :project => project
    project.reload
    assert_not_nil project.wiki
    project.enabled_module_names = []
    project.reload
    assert_no_difference 'Wiki.count' do
      project.enabled_module_names = ['wiki']
    end
    assert_not_nil project.wiki
  end
end
