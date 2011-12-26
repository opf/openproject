#-- encoding: UTF-8
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
require File.expand_path('../../../../test_helper', __FILE__)

class ChiliProject::LiquidTest < ActionView::TestCase
  include ApplicationHelper

  context "hello_world tag" do
    should "render 'Hello world!'" do
      text = "{% hello_world %}"
      assert_match /Hello world!/, textilizable(text)
    end
  end

  context "variables" do
    should "render a list of the current variables" do
      text = "{{ variables | to_list }}"
      formatted = textilizable(text)

      assert formatted.include?('<ul>'), "Not in a list format"
      assert formatted.include?('current_user')
    end

    should "be lazily evaluated" do
      text = ["{{ variables | to_list }}"]
      text << '{% assign foo = \"bar\" %}'
      text << "{{ variables | to_list }}"
      formatted = textilizable(text.join("\n"))

      assert (formatted.scan('<ul>').size == 2), "Not in a list format"
      assert (formatted.scan('current_user').size == 2)

      assert (formatted.scan('foo').size == 1), "Not updated on added variable"
    end
  end

  context "child_pages tag" do
    context "with no arg" do
      context "and @project set" do
        should "should list all wiki pages for the current project" do
          @project = Project.generate!.reload
          wiki = @project.wiki
          top = WikiPage.generate!(:wiki => wiki, :title => 'Top', :content => WikiContent.new(:text => 'top page'))
          child1 = WikiPage.generate!(:wiki => wiki, :title => 'Child1', :content => WikiContent.new(:text => 'child'), :parent => top)

          text = "{% child_pages %}"
          formatted = textilizable(text)

          assert formatted.include?('pages-hierarchy')
          assert formatted.include?('Child1')
          assert formatted.include?('Top')
        end
      end

      context "and no @project set" do
        should "render a warning" do
          text = "{% child_pages %}"
          formatted = textilizable(text)

          assert_match /flash error/, formatted
          assert formatted.include?('With no argument, this tag can be called from projects only')
        end
      end

    end

    context "with a valid WikiPage arg" do
      should "list all child pages for the wiki page" do
        @project = Project.generate!.reload
        wiki = @project.wiki
        top = WikiPage.generate!(:wiki => wiki, :title => 'Top', :content => WikiContent.new(:text => 'top page'))
        child1 = WikiPage.generate!(:wiki => wiki, :title => 'Child1', :content => WikiContent.new(:text => 'child'), :parent => top)

        text = "{% child_pages 'Top' %}"
        formatted = textilizable(text)

        assert formatted.include?('pages-hierarchy')
        assert formatted.include?('Child1')
        assert !formatted.include?('Top')
      end

      should "allow cross project listings even when outside of a project" do
        project = Project.generate!.reload # project not an ivar
        wiki = project.wiki
        top = WikiPage.generate!(:wiki => wiki, :title => 'Top', :content => WikiContent.new(:text => 'top page'))
        child1 = WikiPage.generate!(:wiki => wiki, :title => 'Child1', :content => WikiContent.new(:text => 'child'), :parent => top)

        text = "{% child_pages #{project.identifier}:'Top' %}"
        formatted = textilizable(text)

        assert formatted.include?('pages-hierarchy')
        assert formatted.include?('Child1')
        assert !formatted.include?('Top')
      end

      should "show the WikiPage when parent=1 is set" do
        @project = Project.generate!.reload
        wiki = @project.wiki
        top = WikiPage.generate!(:wiki => wiki, :title => 'Top', :content => WikiContent.new(:text => 'top page'))
        child1 = WikiPage.generate!(:wiki => wiki, :title => 'Child1', :content => WikiContent.new(:text => 'child'), :parent => top)

        text = "{% child_pages 'Top', 'parent=1' %}"
        formatted = textilizable(text)

        assert formatted.include?('pages-hierarchy')
        assert formatted.include?('Child1')
        assert formatted.include?('Top')

      end
    end

    context "with an invalid arg" do
      should "render a warning" do
        @project = Project.generate!.reload
        wiki = @project.wiki
        top = WikiPage.generate!(:wiki => wiki, :title => 'Top', :content => WikiContent.new(:text => 'top page'))
        child1 = WikiPage.generate!(:wiki => wiki, :title => 'Child1', :content => WikiContent.new(:text => 'child'), :parent => top)

        text = "{% child_pages 1 %}"
        formatted = textilizable(text)

        assert_match /flash error/, formatted
        assert formatted.include?('No such page')

      end
    end
  end

  context "include tag" do
    setup do
      @project = Project.generate!.reload
      @wiki = @project.wiki
      @included_page = WikiPage.generate!(:wiki => @wiki, :title => 'Included_Page', :content => WikiContent.new(:text => 'included page [[Second_Page]]'))

      @project2 = Project.generate!.reload
      @cross_project_page = WikiPage.generate!(:wiki => @project2.wiki, :title => 'Second_Page', :content => WikiContent.new(:text => 'second page'))

    end

    context "with a direct page" do
      should "show the included page's content" do
        text = "{% include 'Included Page' %}"
        formatted = textilizable(text)

        assert formatted.include?('included page')
      end
    end

    context "with a cross-project page" do
      should "show the included page's content" do
        text = "{% include '#{@project2.identifier}:Second Page' %}"
        formatted = textilizable(text)

        assert formatted.include?('second page')
      end
    end

    context "with recursive includes" do
      should "render all child pages" do
        parent = WikiPage.generate!(:wiki => @wiki, :title => 'Recursive_Parent', :content => WikiContent.new(:text => "h1. Parent\r\n{% include 'Recursive_Child1' %}"))
        child1 = WikiPage.generate!(:wiki => @wiki, :title => 'Recursive_Child1', :content => WikiContent.new(:text => "h1. Child1\r\n{% include 'Recursive_Child2' %}"))
        child2 = WikiPage.generate!(:wiki => @wiki, :title => 'Recursive_Child2', :content => WikiContent.new(:text => 'h1. Child2'))

        formatted = textilizable(parent.reload.text)

        assert_match /<h1.*?>\s*Parent.*?<\/h1>/, formatted
        assert_match /<h1.*?>\s*Child1.*?<\/h1>/, formatted
        assert_match /<h1.*?>\s*Child2.*?<\/h1>/, formatted

        # make sure there are no dangling html result variables
        assert_no_match /!!html_results.*?!!/, formatted
      end
    end

    context "with a circular inclusion" do
      should "render a warning" do
        circle_page = WikiPage.generate!(:wiki => @wiki, :title => 'Circle', :content => WikiContent.new(:text => '{% include "Circle2" %}'))
        circle_page2 = WikiPage.generate!(:wiki => @wiki, :title => 'Circle2', :content => WikiContent.new(:text => '{% include "Circle" %}'))
        formatted = textilizable(circle_page.reload.text)

        assert_match /flash error/, formatted
        assert_match 'Circular inclusion detected', formatted
      end
    end

    context "with an invalid arg" do
      should "render a warning" do
        text = "{% include '404' %}"
        formatted = textilizable(text)

        assert_match /flash error/, formatted
        assert formatted.include?('No such page')
      end

      should "HTML escape the error" do
        text = "{% include '<script>alert(\"foo\"):</script>' %}"
        formatted = textilizable(text)

        assert formatted.include?("No such page '&lt;script&gt;alert(&quot;foo&quot;):&lt;/script&gt;'")
      end
    end

    context "legacy" do
      should "map to native include" do
        text = "{{include(#{@project2.identifier}:Second_Page)}}"
        formatted = textilizable(text)

        assert formatted.include?('second page')
      end
    end
  end

  context "invalid input" do
    should "be escaped" do
      text =  "{% --- something invalid %}\n"
      text << '<script>alert("Hello")</script>'

      formatted = textilizable(text)
      assert_match  '&lt;script&gt;alert(&quot;Hello&quot;)&lt;/script&gt;', formatted
    end
  end
end
