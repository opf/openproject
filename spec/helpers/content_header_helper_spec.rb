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

describe ContentHeaderHelper, type: :helper do

  describe 'simple content_header' do
    it 'can be drawn with a proper title' do
      header = content_header title: 'Foo'
      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar" role="navigation">
            <div class="title-container">
              <h2 title="Foo">Foo</h2>
            </div>
            <ul class="toolbar-items" role="menubar"></ul>
          </div>
        </div>
      }
    end

    it 'can accept toolbar menu items' do
      header = content_header title: 'Foo' do |h|
        h.toolbar do |t|
          t.button 'Test', root_path
        end
      end

      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar" role="navigation">
            <div class="title-container">
              <h2 title="Foo">Foo</h2>
            </div>
            <ul class="toolbar-items" role="menubar">
              <li class="toolbar-item" role="menuitem">
                <a href="/" class="button" tabindex="1">
                  <span class="button--text">Test</span>
                </a>
              </li>
            </ul>
          </div>
        </div>
      }
    end

    it 'can draw icons, accesskeys and highlights as builtin' do
      header = content_header title: 'Foo' do |h|
        h.toolbar do |t|
          t.button('Add', root_path, icon: :add, highlight: :alt) +
          t.button('Edit', '/edit/42', icon: :edit, highlight: :default, accesskey: :edit) +
          t.button('Delete', '/delete', icon: :delete, data: { method: :delete })
        end
      end

      expect(header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar" role="navigation">
            <div class="title-container">
              <h2 title="Foo">Foo</h2>
            </div>
            <ul class="toolbar-items" role="menubar">
              <li class="toolbar-item" role="menuitem">
                <a href="/" class="button -alt-highlight" tabindex="1">
                  <i class="button--icon icon-add"></i>
                  <span class="button--text">Add</span>
                </a>
              </li>
              <li class="toolbar-item" role="menuitem">
                <a href="/edit/42" accesskey="3" class="button -highlight" tabindex="2">
                  <i class="button--icon icon-edit"></i>
                  <span class="button--text">Edit</span>
                </a>
              </li>
              <li class="toolbar-item" role="menuitem">
                <a href="/delete" class="button" tabindex="3" data-method="delete">
                  <i class="button--icon icon-delete"></i>
                  <span class="button--text">Delete</span>
                </a>
              </li>
            </ul>
          </div>
        </div>
      }
    end
  end

end
