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

# The reporting engine that computes a cost report: the filters, group bys,
# results and SQL below this namespace, plus the state a chain needs while it is
# built. A report itself is a CostReport record, which hosts the chain - see
# CostReports::EngineChain.
module CostQuery
  class << self
    def engine
      self
    end

    def reporting_connection
      ApplicationRecord.connection
    end

    # Report::QueryUtils sanitizes through the engine, which used to be an
    # ActiveRecord model.
    def sanitize_sql_for_conditions(statement)
      ApplicationRecord.send(:sanitize_sql_for_conditions, statement)
    end

    def accepted_properties
      @accepted_properties ||= []
    end

    # Chainables register blocks here to add themselves to every new chain, e.g.
    # the permission filter that limits the entries a user may see.
    def chain_initializer
      @chain_initializer ||= []
    end
  end
end
