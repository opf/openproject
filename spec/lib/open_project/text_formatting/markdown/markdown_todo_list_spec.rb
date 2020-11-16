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
require_relative './expected_markdown'

describe OpenProject::TextFormatting,
         'Todo lists' do
  include_context 'expected markdown modules'

  context 'With a todo list in a table' do
    it_behaves_like 'format_text produces' do
      let(:raw) do
        <<~RAW
          <table>
            <tbody>
              <tr>
                <td>
                  <ul class="todo-list">
                    <li>
                      <code class='op-uc-code'>
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
                      <code class='op-uc-code'>
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
    end
  end

  context 'with a todo list with a link on second place' do
    it_behaves_like 'format_text produces' do
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
    end
  end
end
