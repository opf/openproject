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

require 'date'

module ReportingEngine::Patches::ToDatePatch
  module StringAndNil
    ::String.send(:include, self)
    ::NilClass.send(:include, self)

    def to_dateish
      return Date.today if blank?
      Date.parse self
    end
  end

  module DateAndTime
    ::Date.send(:include, self)
    ::Time.send(:include, self)

    def to_dateish
      self
    end

    def force_utc
      return to_time.force_utc unless respond_to? :utc_offset
      return self if utc?
      utc - utc_offset
    end
  end
end
