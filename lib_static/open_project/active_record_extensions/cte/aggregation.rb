# frozen_string_literal: true

# -- copyright
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
# ++

module OpenProject
  module ActiveRecordExtensions
    module Cte
      # Process-global registry of static CTE SQL templates, keyed by CTE name.
      # Templates are callables (->(params) { sql }); per-user values are supplied
      # as params at render time and never stored here, so the shared registry
      # holds no request-specific SQL. Serves as the fallback template source when
      # a provider node carries no inline body.
      module Aggregation
        module_function

        # Register the CTE template +cte+ (a callable ->(params) { sql }) under +name+.
        def register(name, cte)
          registered[name] = cte
        end

        # Remove the template registered under +name+.
        def deregister(name)
          registered.delete(name)
        end

        # The registry: a name => template hash with indifferent access.
        def registered
          @registered ||= {}.with_indifferent_access
        end
      end
    end
  end
end
