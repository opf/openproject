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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec::Matchers.define :have_sortable_item do |record, type:, label: record.try(:name)|
  identity = "[data-sortable-lists--item-id-value='#{record.id}']" \
             "[data-sortable-lists--item-type-value='#{type}']"
  selector = "[data-controller~='sortable-lists--item']#{identity}"

  def capybara_node(rendered)
    rendered.respond_to?(:has_css?) ? rendered : Capybara.string(rendered.to_s)
  end

  match do |rendered|
    node = capybara_node(rendered)
    node.has_css?(selector, count: 1) &&
      node.find(selector)["data-sortable-lists--item-label-value"] == label
  end

  match_when_negated do |rendered|
    capybara_node(rendered).has_no_css?(identity)
  end

  failure_message do
    "expected one sortable-lists item of type #{type.inspect} with id #{record.id} and label #{label.inspect}"
  end
end
