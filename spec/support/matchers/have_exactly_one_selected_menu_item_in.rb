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

RSpec::Matchers.define :have_exactly_one_selected_menu_item_in do |menu|
  match do |actual|
    build_failure_message(menu, actual) == nil
  end

  failure_message do |actual|
    build_failure_message(menu, actual)
  end

  description do
    "have exactly one selected menu item in #{menu}"
  end

  failure_message_when_negated do |_actual|
    raise 'You should not use this matcher for should_not matches'
  end

  def build_failure_message(menu, actual)
    menu_selector = HTML::Selector.new(selector_for_menu(menu))
    menu_item_selector = HTML::Selector.new('a.selected')

    html = HTML::Document.new(actual.is_a?(String) ? actual : actual.body)

    menu_matches = menu_selector.select(html.root)
    if menu_matches.size == 1
      menu_item_matches = menu_item_selector.select(menu_matches.first)

      if menu_item_matches.size == 0
        "Expected to find exactly one selected menu item in #{menu}, but found none."
      elsif menu_item_matches.size > 1
        "Expected to find exactly one selected menu item in #{menu}, but found #{menu_item_matches.size}."
      else
        nil
      end
    else
      "Expected to find #{menu.inspect} in document, but didn't."
    end
  end

  def selector_for_menu(menu)
    case menu
    when :project_menu
      '#main-menu'
    else
      raise ArgumentError, 'Unknown menu identifier'
    end
  end
end
