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

describe UiComponents::Dsl::ContentHeader do
  let(:dsl) { Object.new.extend(described_class) }

  describe '#content_header' do
    let(:content_header) { dsl.content_header title: 'Lorem', subtitle: 'ipsum' }

    it 'should create a content header' do
      expect(content_header).to be_html_eql %{
        <div class="toolbar-container">
          <div class="toolbar" role="navigation">
            <div class="title-container">
              <h2 role="heading" title="Lorem">Lorem</h2>
            </div>
            <ul class="toolbar-items" role="menubar"></ul>
          </div>
          <p class="subtitle">ipsum</p>
        </div>
      }
    end

    describe '#toolbar w/ #button' do
      let(:content_header) do
        dsl.content_header title: 'Lorem', subtitle: 'ipsum' do |h|
          h.toolbar do |t|
            t.button 'Edit', '/somewhere/over/the/rainbow',
                     icon: :edit, accesskey: :edit
          end
        end
      end

      it 'should create a header with a toolbar and a button' do
        expect(content_header).to be_html_eql %{
          <div class="toolbar-container">
            <div class="toolbar" role="navigation">
              <div class="title-container">
                <h2 role="heading" title="Lorem">Lorem</h2>
              </div>
              <ul class="toolbar-items" role="menubar">
                <li class="toolbar-item" role="menuitem">
                  <a href="/somewhere/over/the/rainbow" class="button" role="button" accesskey="3">
                    <i class="button--icon icon-edit"></i>
                    <span class="button--text">Edit</span>
                  </a>
                </li>
              </ul>
            </div>
            <p class="subtitle">ipsum</p>
          </div>
        }
      end
    end

    describe '#toolbar w/ #button and #submenu' do
      let(:content_header) do
        dsl.content_header title: 'Lorem' do |h|
          h.toolbar do |t|
            t.button 'Edit', '/somewhere/over/the/rainbow',
                     icon: :edit, accesskey: :edit
            t.submenu title: 'dolor', icon: :sit, accesskey: :more_menu do |s|
              s.submenu_item 'amet', '/way/up/high', icon: :sun
              s.submenu_divider
              s.submenu_item 'non', '/way/down/below', icon: :moon
            end
          end
        end
      end

      it 'should render the submenu with it\'s item properly' do
        expect(content_header).to be_html_eql %{
          <div class="toolbar-container">
            <div class="toolbar" role="navigation">
              <div class="title-container">
                <h2 role="heading" title="Lorem">Lorem</h2>
              </div>
              <ul class="toolbar-items" role="menubar">
                <li class="toolbar-item" role="menuitem">
                  <a href="/somewhere/over/the/rainbow" class="button" role="button" accesskey="3">
                    <i class="button--icon icon-edit"></i>
                    <span class="button--text">Edit</span>
                  </a>
                </li>
                <li class="toolbar-item -with-submenu"
                    role="menuitem"
                    aria-haspopup="true"
                    title="dolor"
                  >
                  <a class="button" href="#" accesskey="7">
                    <i class="button--icon icon-sit"></i>
                    <span class="button--text">dolor</span>
                    <i class="button--dropdown-indicator"></i>
                  </a>
                  <ul class="toolbar-submenu" aria-hidden="true" role="menu">
                    <li class="toolbar-item" role="menuitem">
                      <a href="/way/up/high">
                        <i class="button--icon icon-sun"></i>
                        <span class="button--text">amet</span>
                      </a>
                    </li>
                    <li class="toolbar-item -divider" role="listitem"></li>
                    <li class="toolbar-item" role="menuitem">
                      <a href="/way/down/below">
                        <i class="button--icon icon-moon"></i>
                        <span class="button--text">non</span>
                      </a>
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
          </div>
        }
      end
    end
  end
end
