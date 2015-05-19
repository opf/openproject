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

require 'spec_helper'

describe ToolbarHelper, type: :helper do
  describe '#toolbar' do
    it 'should create a default toolbar' do
      result = toolbar title: 'Title'
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div id="toolbar">
            <div class="title-container">
              <h2 title="Title">Title</h2>
            </div>
            <ul id="toolbar-items"></ul>
          </div>
        </div>
      }
    end

    it 'should be able to add a subtitle' do
      result = toolbar title: 'Title', subtitle: 'lorem'
      expect(result).to be_html_eql %{
        <div class="toolbar-container">
          <div id="toolbar">
            <div class="title-container">
              <h2 title="Title">Title</h2>
            </div>
            <ul id="toolbar-items"></ul>
          </div>
          <p class="subtitle">lorem</p>
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
          <div id="toolbar">
            <div class="title-container">
              <h2 title="Title">Title</h2>
            </div>
            <ul id="toolbar-items">
              <li>
                <p data-number="2">paragraph</p>
              </li>
            </ul>
          </div>
        </div>
      }
    end
  end
end
