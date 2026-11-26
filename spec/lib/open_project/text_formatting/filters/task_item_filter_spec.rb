# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::TextFormatting::Filters::TaskItemFilter do
  subject(:output) { described_class.call(html, context: {}) }

  let(:page) { Capybara.string(output) }

  context "with a checked item" do
    let(:html) { '<ul data-task-list><li data-task><span data-task="checked">Send <em>invoice</em></span></li></ul>' }

    it "labels a checked item with its text" do
      expect(page).to have_checked_field("Send invoice", disabled: true, exact: true)
      expect(output).to include('class="op-uc-list_task-list"')
      expect(output).to include('class="op-uc-list--item_task"')
      expect(output).not_to include("data-task")
    end
  end

  context "with an unchecked item" do
    let(:html) { '<ul data-task-list><li data-task><span data-task="unchecked">open</span></li></ul>' }

    it "labels an unchecked item" do
      expect(page).to have_unchecked_field("open", disabled: true, exact: true)
    end
  end

  context "with a nested list" do
    let(:html) do
      '<ul data-task-list><li data-task><span data-task="checked">a</span>' \
        '<ul data-task-list><li data-task><span data-task="unchecked">b</span></li></ul></li></ul>'
    end

    it "keeps the nested list outside the label" do
      expect(page).to have_css("label", count: 2)
      expect(page).to have_field(type: "checkbox", disabled: true, count: 2)
      expect(page).to have_no_css("label ul")
    end
  end

  context "with an unknown task value" do
    let(:html) { '<span data-task="bogus">x</span>' }

    it "ignores unknown task values" do
      expect(page).to have_no_field(type: "checkbox")
      expect(output).not_to include("data-task")
    end
  end

  context "with an existing class" do
    let(:html) { '<ul data-task-list class="foo op-uc-list_task-list"><li>x</li></ul>' }

    it "appends without duplicating" do
      expect(output).to include('class="foo op-uc-list_task-list"')
    end
  end
end
