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

# Extending Capybara to allow a flagged check for has_selector to avoid
# lots of if/else. Extension is available for both the `Capybara::Session`
# and `Capybara::Node::Matchers`, thus the matcher can be used on both on the
# `page` or any element (Capybara::Node::Element).
#   - expect(page).to have_conditional_selector(...)
#   - expect(input).to have_conditional_selector(...)

module Capybara
  module Node
    module Matchers
      def has_conditional_selector?(condition, *, **kw_args)
        if condition
          has_selector?(*, **kw_args)
        else
          has_no_selector?(*, **kw_args)
        end
      end
    end
  end
end

module Capybara
  class Session
    def has_conditional_selector?(...)
      @touched = true
      current_scope.has_conditional_selector?(...)
    end
  end
end
