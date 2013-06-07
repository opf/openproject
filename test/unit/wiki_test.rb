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

class WikiTest < ActiveSupport::TestCase
  fixtures :all

  def test_create
    wiki = Wiki.new(:project => Project.find(2))
    assert !wiki.save
    assert_equal 1, wiki.errors.count

    wiki.start_page = "Start page"
    assert wiki.save
  end

  def test_update
    @wiki = Wiki.find(1)
    @wiki.start_page = "Another start page"
    assert @wiki.save
    @wiki.reload
    assert_equal "Another start page", @wiki.start_page
  end

  def test_find_page
    wiki = Wiki.find(1)
    page = WikiPage.find(2)

    assert_equal page, wiki.find_page('Another_page')
    assert_equal page, wiki.find_page('Another page')
    assert_equal page, wiki.find_page('ANOTHER page')

    page = WikiPage.find(10)
    assert_equal page, wiki.find_page('Этика_менеджмента')

    page = WikiPage.generate!(:wiki => wiki, :title => '2009\\02\\09')
    assert_equal page, wiki.find_page('2009\\02\\09')
  end

  def test_titleize
    assert_equal 'Page_title_with_CAPITALES', Wiki.titleize('page title with CAPITALES')
    assert_equal 'テスト', Wiki.titleize('テスト')
  end

  context "#sidebar" do
    setup do
      @wiki = Wiki.find(1)
    end

    should "return nil if undefined" do
      assert_nil @wiki.sidebar
    end

    should "return a WikiPage if defined" do
      page = @wiki.pages.new(:title => 'Sidebar')
      page.content = WikiContent.new(:text => 'Side bar content for test_show_with_sidebar')
      page.save!

      assert_kind_of WikiPage, @wiki.sidebar
      assert_equal 'Sidebar', @wiki.sidebar.title
    end
  end
end
