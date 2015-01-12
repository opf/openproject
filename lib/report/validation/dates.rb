#-- copyright
# ReportingEngine
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

module Report::Validation
  module Dates
    def validate_dates(*values)
      values = values.flatten
      return true if values.empty?
      values.flatten.all? do |val|
        begin
          !!val.to_dateish
        rescue ArgumentError
          errors[:date] << val
          validate_dates(values - [val])
          false
        end
      end
    end
  end
end
