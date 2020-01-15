#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ToolbarHelper, type: :helper do
  describe '.toolbar' do
    it 'should create a default toolbar' do
      result = toolbar title: 'Title'
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>Title</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end

    it 'should be able to add a subtitle' do
      result = toolbar title: 'Title', subtitle: 'lorem'
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>Title</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
          <p class="subtitle">lorem</p>
        </div>
      }
    end

    it 'should be able to add a link_to' do
      result = toolbar title: 'Title', link_to: link_to('foobar', user_path('1234'))
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>Title: <a href="/users/1234">foobar</a></h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end

    it 'should escape the title' do
      result = toolbar title: '</h2><script>alert("foobar!");</script>'
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>&lt;/h2&gt;&lt;script&gt;alert(&quot;foobar!&quot;);&lt;/script&gt;</h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end

    it 'should include capsulate html' do
      result = toolbar title: 'Title' do
        content_tag :li do
          content_tag :p, 'paragraph', data: { number: 2 }
        end
      end
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>Title</h2>
            </div>
            <ul class="toolbar-items">
              <li>
                <p data-number="2">paragraph</p>
              </li>
            </ul>
          </div>
        </div>
      }
    end
  end
  describe '.breadcrumb_toolbar' do
    it 'should escape properly' do
      result = breadcrumb_toolbar '</h2><script>alert("foobar!");</script>',
                                  link_to('foobar', user_path('1234'))

      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar">
            <div class="title-container">
              <h2>&lt;/h2&gt;&lt;script&gt;alert(&quot;foobar!&quot;);&lt;/script&gt; &raquo; <a href="/users/1234">foobar</a></h2>
            </div>
            <ul class="toolbar-items"></ul>
          </div>
        </div>
      }
    end
  end
end
