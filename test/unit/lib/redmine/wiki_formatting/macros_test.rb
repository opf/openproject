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

require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::WikiFormatting::MacrosTest < HelperTestCase
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods

  fixtures :projects, :roles, :enabled_modules, :users,
                      :repositories, :changesets,
                      :trackers, :issue_statuses, :issues,
                      :versions, :documents,
                      :wikis, :wiki_pages, :wiki_contents,
                      :boards, :messages,
                      :attachments

  def setup
    super
    @project = nil
  end

  def teardown
  end

  def test_macro_hello_world
    text = "{{hello_world}}"
    assert textilizable(text).match(/Hello world!/)
  end

  def test_macro_include
    @project = Project.find(1)
    # include a page of the current project wiki
    text = "{{include(Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)

    @project = nil
    # include a page of a specific project wiki
    text = "{{include(ecookbook:Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)

    text = "{{include(ecookbook:)}}"
    assert textilizable(text).match(/CookBook documentation/)

    text = "{{include(unknowidentifier:somepage)}}"
    assert textilizable(text).match(/No such page/)
  end

  def test_macro_child_pages
    expected =  "<p><ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>\n" +
                 "</ul>\n</p>"

    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, textilizable("{{child_pages}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, textilizable("{{child_pages(Another_page)}}", :object => WikiPage.find(1).content)

    @project = Project.find(2)
    assert_equal expected, textilizable("{{child_pages(ecookbook:Another_page)}}", :object => WikiPage.find(1).content)
  end

  def test_macro_child_pages_with_option
    expected =  "<p><ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Another_page\">Another page</a>\n" +
                 "<ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>\n" +
                 "</ul>\n</li>\n</ul>\n</p>"

    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, textilizable("{{child_pages(parent=1)}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, textilizable("{{child_pages(Another_page, parent=1)}}", :object => WikiPage.find(1).content)

    @project = Project.find(2)
    assert_equal expected, textilizable("{{child_pages(ecookbook:Another_page, parent=1)}}", :object => WikiPage.find(1).content)
  end
end
