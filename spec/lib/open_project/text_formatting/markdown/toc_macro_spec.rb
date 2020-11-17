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
         'toc macro' do
  include_context 'expected markdown modules'

  it_behaves_like 'format_text produces' do
    let(:raw) do
      <<~RAW
        <macro class="toc"></macro>

        # The first h1 heading

        Some text after the first h1 heading

        ## The first h2 heading

        Some text after the first h2 heading

        ### The first h3 heading

        Some text after the first h3 heading

        # The second h1 heading

        Some text after the second h1 heading

        ## The second h2 heading

        Some text after the second h2 heading

        ### The second h3 heading

        Some text after the second h3 heading
      RAW
    end

    let(:expected) do
      <<~EXPECTED
        <p class="op-uc-p">
          <nav class="op-uc-toc">
            <h1 class="op-uc-toc--title">Table of contents</h1>
            <ul class="op-uc-toc--list">
              <li class="op-uc-toc--list-item">
                <a class="op-uc-link" href="#the-first-h1-heading">The first h1 heading</a>
              </li>
              <ul class="op-uc-toc--list">
                <li class="op-uc-toc--list-item">
                  <a class="op-uc-link" href="#the-first-h2-heading">The first h2 heading</a>
                </li>
                <ul class="op-uc-toc--list">
                  <li class="op-uc-toc--list-item">
                    <a class="op-uc-link" href="#the-first-h3-heading">The first h3 heading</a>
                  </li>
                </ul>
              </ul>
              <li class="op-uc-toc--list-item">
                <a class="op-uc-link" href="#the-second-h1-heading">The second h1 heading</a>
              </li>
              <ul class="op-uc-toc--list">
                <li class="op-uc-toc--list-item">
                  <a class="op-uc-link" href="#the-second-h2-heading">The second h2 heading</a>
                </li>
                <ul class="op-uc-toc--list">
                  <li class="op-uc-toc--list-item">
                    <a class="op-uc-link" href="#the-second-h3-heading">The second h3 heading</a>
                  </li>
                </ul>
              </ul>
            </ul>
          </nav>
        </p>
        <h1 class="op-uc-h1" id="the-first-h1-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-first-h1-heading" aria-hidden="true">
          </a>
          The first h1 heading
        </h1>
        <p class="op-uc-p">Some text after the first h1 heading</p>
        <h2 class="op-uc-h2" id="the-first-h2-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-first-h2-heading" aria-hidden="true">
          </a>
          The first h2 heading
        </h2>
        <p class="op-uc-p">Some text after the first h2 heading</p>
        <h3 class="op-uc-h3" id="the-first-h3-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-first-h3-heading" aria-hidden="true">
          </a>
          The first h3 heading
        </h3>
        <p class="op-uc-p">Some text after the first h3 heading</p>
        <h1 class="op-uc-h1" id="the-second-h1-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-second-h1-heading" aria-hidden="true">
          </a>The second h1 heading
        </h1>
        <p class="op-uc-p">Some text after the second h1 heading</p>
        <h2 class="op-uc-h2" id="the-second-h2-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-second-h2-heading" aria-hidden="true">
          </a>The second h2 heading
        </h2>
        <p class="op-uc-p">Some text after the second h2 heading</p>
        <h3 class="op-uc-h3" id="the-second-h3-heading">
          <a class="wiki-anchor icon-paragraph op-uc-link" href="#the-second-h3-heading" aria-hidden="true">
          </a>The second h3 heading
        </h3>
        <p class="op-uc-p">Some text after the second h3 heading</p>
      EXPECTED
    end
  end
end
