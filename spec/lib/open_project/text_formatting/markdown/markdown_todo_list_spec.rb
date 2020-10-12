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

describe OpenProject::TextFormatting,
         'Todo lists',
         # Speeds up the spec by avoiding event mailers to be procssed
         with_settings: {notified_events: []} do
  include OpenProject::TextFormatting
  include ERB::Util
  include WorkPackagesHelper # soft-dependency
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end

  describe '.format_text' do
    context 'With a todo list in a table' do
      let(:raw) do
        <<~RAW
          <table>
            <tbody>
              <tr>
                <td>
                  <ul class="todo-list">
                    <li>
                      <code>
                        <label class="todo-list__label"><input type="checkbox" disabled="disabled">
                          <span class="todo-list__label__description">asdf</span>
                        </label>
                      </code>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="todo-list">
                    <li>
                      <a href="https://example.com/">
                        <label class="todo-list__label">
                          <input type="checkbox" disabled="disabled">
                          <span class="todo-list__label__description">asdfasd</span>
                        </label>
                        <span class="todo-list__label__description"> asdf</span>
                      </a>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="todo-list">
                    <li>
                      <label class="todo-list__label">
                        <input type="checkbox" disabled="disabled">
                        <span
                          class="todo-list__label__description">asdfasdf</span>
                        </label>
                      </li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td>
                  <ul class="todo-list">
                    <li>
                      <label class="todo-list__label">
                        <input type="checkbox" disabled="disabled">
                      </label>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="todo-list">
                    <li>
                      <label class="todo-list__label">
                        <strong>
                          <input type="checkbox" disabled="disabled">
                        </strong>
                        <span
                          class="todo-list__label__description">
                          <strong>asdf</strong>
                        </span>
                      </label>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="todo-list">
                    <li>
                      <label class="todo-list__label">
                        <input type="checkbox" disabled="disabled"></label>
                      </li>
                  </ul>
                </td>
              </tr>
            </tbody>
          </table>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <table>
            <tbody>
              <tr>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                      <code>
                          <span>asdf</span>
                      </code>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                      <a href="https://example.com/" rel="noopener noreferrer">
                        <span>asdfasd</span>
                        <span> asdf</span>
                      </a>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                      <span>asdfasdf</span>
                    </li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                      <strong></strong>
                      <span><strong>asdf</strong></span>
                    </li>
                  </ul>
                </td>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                    </li>
                  </ul>
                </td>
              </tr>
            </tbody>
          </table>
        EXPECTED
      end


      subject { format_text(raw) }

      it 'should correctly place todo lists in table' do
        expect(subject).to be_html_eql(expected)
      end
    end

    describe 'with a todo list with a link on second place' do
      let(:raw) do
        <<~RAW
          <table>
            <tbody>
              <tr>
                <td>asdf</td>
                <td>asdfasdf</td>
              </tr>
              <tr>
                <td>
                  <ul class="todo-list">
                    <li>
                      <label class="todo-list__label"><input type="checkbox" disabled="disabled">
                        <span class="todo-list__label__description">asdfasdfasdf </span>
                      </label>
                      <a href="https://example.com/">
                        <label class="todo-list__label">
                          <span class="todo-list__label__description">foobar</span>
                        </label>
                      </a>
                    </li>
                  </ul>
                </td>
                <td></td>
              </tr>
            </tbody>
          </table>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <table>
            <tbody>
              <tr>
                <td>asdf</td>
                <td>asdfasdf</td>
              </tr>
              <tr>
                <td>
                  <ul class="task-list">
                    <li class="task-list-item">
                      <input type="checkbox" class="task-list-item-checkbox" disabled>
                      <span>asdfasdfasdf </span>
                      <a href="https://example.com/" rel="noopener noreferrer">
                        <span>foobar</span>
                      </a>
                    </li>
                  </ul>
                </td>
                <td></td>
              </tr>
            </tbody>
          </table>
        EXPECTED
      end

      subject { format_text(raw) }

      it 'should correctly place the link after the text node' do
        expect(subject).to be_html_eql(expected)
      end
    end
  end
end
