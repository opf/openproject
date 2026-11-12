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

Capybara.add_selector(:rich_text_field, locator_type: [String, Symbol]) do
  label "rich text field (CKEditor)"

  xpath do |locator, **_options|
    xpath = XPath.descendant(:"opce-ckeditor-augmented-textarea")
    next xpath if locator.nil?

    # All the complexity is caused by the need to have the textarea id be a json
    # string (to be parsed by populateInputsFromDataset), so following would not
    # work due concat function unlike = operator using only first node in the
    # node set, so doesn't work if there are multiple labels with text "foo":
    #
    # .//opce-ckeditor-augmented-textarea[
    #   ./@data-text-area-id = concat('"', //label[contains(text(), 'foo')]/@for, '"')
    # ]
    #
    # Alternatively we could construct more complicated xpath that would search
    # for opce tag that has textarea id matching attribute of label that matches
    # opce tag textarea id, but that double matching looks worse than more
    # complicated search:
    #
    # .//opce-ckeditor-augmented-textarea[
    #   ./@data-text-area-id = concat('"', //label[
    #     contains(text(), 'foo') and
    #     concat('"', ./@for, '"') = //opce-ckeditor-augmented-textarea/@data-text-area-id
    #   ]/@for, '"')
    # ]
    locator = locator.to_s
    text_area_id = XPath.attr(:"data-text-area-id")
    attr_matcher = [
      text_area_id.starts_with('"'),
      text_area_id.substring(text_area_id.string_length) == '"',
      text_area_id.substring(2, text_area_id.string_length.minus(2)) ==
        XPath.anywhere(:label)[XPath.string.n.is(locator)].attr(:for)
    ].inject(:&)
    xpath[attr_matcher] + locate_label(locator).descendant(xpath)
  end
end

module Capybara
  module RSpecMatchers
    def have_rich_text_field(locator = nil, **, &)
      Matchers::HaveSelector.new(:rich_text_field, locator, **, &)
    end

    def have_no_rich_text_field(locator = nil, **, &)
      Matchers::NegatedMatcher.new(have_rich_text_field(locator, **, &))
    end
  end
end
