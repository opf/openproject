#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting,
               "blockquote" do
  include_context "expected markdown modules"

  it_behaves_like "format_text produces" do
    let(:raw) do
      <<~RAW
        John said:
        > Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.
        > Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.
        >
        > * Donec odio lorem,
        > * sagittis ac,
        > * malesuada in,
        > * adipiscing eu, dolor.
        >
        > >Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.
        >
        > Proin a tellus. Nam vel neque.

        He's right.

        >Second quote
      RAW
    end

    let(:expected) do
      <<~EXPECTED
        <p class="op-uc-p">John said:</p>
        <blockquote class="op-uc-blockquote">
        <p class="op-uc-p">Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.<br>
        Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.</p>
        <ul class="op-uc-list">
          <li class="op-uc-list--item">Donec odio lorem,</li>
          <li class="op-uc-list--item">sagittis ac,</li>
          <li class="op-uc-list--item">malesuada in,</li>
          <li class="op-uc-list--item">adipiscing eu, dolor.</li>
        </ul>
        <blockquote class="op-uc-blockquote">
        <p class="op-uc-p">Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.</p>
        </blockquote>
        <p class="op-uc-p">Proin a tellus. Nam vel neque.</p>
        </blockquote>
        <p class="op-uc-p">He's right.</p>
        <blockquote class="op-uc-blockquote">
        <p class="op-uc-p">Second quote</p>
        </blockquote>
      EXPECTED
    end
  end
end
