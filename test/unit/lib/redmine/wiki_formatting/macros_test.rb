#-- encoding: UTF-8
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

require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::WikiFormatting::MacrosTest < HelperTestCase
  include ApplicationHelper
  include WorkPackagesHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods

  fixtures :all

  def setup
    super
    @project = nil
  end

  def test_macro_hello_world
    text = "{{hello_world}}"
    assert format_text(text).match(/Hello world!/)
    # escaping
    text = "!{{hello_world}}"
    assert_equal '<p>{{hello_world}}</p>', format_text(text)
  end

  def test_macro_include
    @project = Project.find(1)
    # include a page of the current project wiki
    text = "{{include(Another page)}}"
    assert format_text(text).match(/This is a link to a ticket/)

    @project = nil
    # include a page of a specific project wiki
    text = "{{include(ecookbook:Another page)}}"
    assert format_text(text).match(/This is a link to a ticket/)

    text = "{{include(ecookbook:)}}"
    assert format_text(text).match(/CookBook documentation/)

    text = "{{include(unknowidentifier:somepage)}}"
    assert format_text(text).match(/Page not found/)
  end

  def test_macro_child_pages
    expected =  "<p><ul class=\"pages-hierarchy\">" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>" +
                 "</ul></p>"

    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, format_text("{{child_pages}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, format_text("{{child_pages(Another_page)}}", :object => WikiPage.find(1).content)

    @project = Project.find(2)
    assert_equal expected, format_text("{{child_pages(ecookbook:Another_page)}}", :object => WikiPage.find(1).content)
  end

  def test_macro_child_pages_with_option
    expected =  "<p><ul class=\"pages-hierarchy\">" +
                 "<li><a href=\"/projects/ecookbook/wiki/Another_page\">Another page</a>" +
                 "<ul class=\"pages-hierarchy\">" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>" +
                 "</ul></li></ul></p>"

    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, format_text("{{child_pages(parent=1)}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, format_text("{{child_pages(Another_page, parent=1)}}", :object => WikiPage.find(1).content)

    @project = Project.find(2)
    assert_equal expected, format_text("{{child_pages(ecookbook:Another_page, parent=1)}}", :object => WikiPage.find(1).content)
  end
end
