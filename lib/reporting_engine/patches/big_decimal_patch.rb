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

module ReportingEngine::Patches::BigDecimalPatch
  module BigDecimal
    ::BigDecimal.send :include, self
    def to_d; self end
  end

  module Integer
    ::Integer.send :include, self
    def to_d; to_f.to_d end
  end

  module String
    ::String.send :include, self
    def to_d; ::BigDecimal.new(self) end
  end

  module NilClass
    ::NilClass.send :include, self
    def to_d; 0 end
  end
end
