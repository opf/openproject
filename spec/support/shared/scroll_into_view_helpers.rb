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

# Scrolls a native element into view using JS
# @param element [Capybara::Node::Element] the element to scroll into view
# @param block [Symbol] (optional) Defines vertical alignment.
#   One of `:start`, `:center`, `:end`, or `:nearest`. Defaults to `:start`.
# @param inline [Symbol] (optional) Defines horizontal alignment.
#   One of `:start`, `:center`, `:end`, or `:nearest`. Defaults to `:nearest`..
def scroll_to_element(element, block: :start, inline: :nearest)
  script = <<-JS
    arguments[0].scrollIntoView({block: "#{block}", inline: "#{inline}"});
  JS
  if using_cuprite?
    page.driver.execute_script(script, element.native)
  else
    Capybara.current_session.driver.browser.execute_script(script, element.native)
  end
end

def scroll_to_and_click(element)
  retry_block do
    scroll_to_element(element)
    element.click
  end
end

def expect_element_in_view(element)
  script = <<-JS
    (function(el) {
      var rect = el.getBoundingClientRect();
      return (
        rect.top >= 0 && rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
      );
    })(arguments[0]);
  JS

  retry_block do
    result = page.evaluate_script(script, element.native)
    raise "Expected #{element} to be visible in window, but wasn't." unless result
  end
end
