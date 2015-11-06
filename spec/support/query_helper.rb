#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

# need to define all the operators
require 'cost_query/operator'

module OpenProject::Reporting
  module QueryHelper
    def minimal_query
      before do
        @query = CostQuery.new
        @query.send(:minimal_chain!)
      end
    end
  end
end

RSpec.configure do |c|
  c.extend OpenProject::Reporting::QueryHelper, reporting_query_helper: true
end
