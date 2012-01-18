#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class WikiPageDropTest < ActiveSupport::TestCase
  def setup
    @project = Project.generate!
    @wiki = Wiki.generate(:project => @project)
    @wiki_page = WikiPage.generate!(:wiki => @wiki)
    User.current = @user = User.generate!
    @role = Role.generate!(:permissions => [:view_wiki_pages])
    Member.generate!(:principal => @user, :project => @project, :roles => [@role])
    @drop = @wiki_page.to_liquid
  end

  context "drop" do
    should "be a WikiPageDrop" do
      assert @drop.is_a?(WikiPageDrop), "drop is not a WikiPageDrop"
    end
  end


  context "#title" do
    should "return the title of the wiki page" do
      assert_equal @wiki_page.title, @drop.title
    end
  end

  should "only load an object if it's visible to the current user" do
    assert User.current.logged?
    assert @wiki_page.visible?

    @private_project = Project.generate!(:is_public => false)
    @private_wiki = Wiki.generate!(:project => @private_project)
    @private_wiki_page = WikiPage.generate!(:wiki => @private_wiki)

    assert !@private_wiki_page.visible?, "WikiPage is visible"
    @private_drop = WikiPageDrop.new(@private_wiki_page)
    assert_equal nil, @private_drop.instance_variable_get("@object")
    assert_equal nil, @private_drop.title
  end
end
