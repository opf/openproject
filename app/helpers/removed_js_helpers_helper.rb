#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Contains tag helpers still existing in the OP code but already
# removed from rails. Please consider removing the occurrences in
# the code rather than adding additional helpers here.

module RemovedJsHelpersHelper
  # removed in rails 4.1
  def link_to_function(content, function, html_options = {})
    id = html_options.delete(:id) { "link-to-function-#{SecureRandom.uuid}" }
    csp_onclick(function, "##{id}")

    content_tag(:a, content, html_options.merge(id:, href: ''))
  end

  ##
  # Execute the callback on click
  def csp_onclick(callback_str, selector, prevent_default: true)
    content_for(:additional_js_dom_ready) do
      "jQuery('#{selector}').click(function() { #{callback_str}; #{prevent_default ? 'return false;' : ''} });\n".html_safe
    end
  end
end
