#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module Redmine #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      # Custom string conversions
      module Conversions
        # Parses hours format and returns a float
        def to_hours
          s = dup
          s.strip!
          if s =~ %r{^(\d+([.,]\d+)?)h?$}
            s = $1
          else
            # 230: 2.5
            s.gsub!(%r{^(\d+):(\d+)$}) do $1.to_i + $2.to_i / 60.0 end
            # 2h30, 2h, 30m => 2.5, 2, 0.5
            s.gsub!(%r{^((\d+)\s*(h|hours?))?\s*((\d+)\s*(m|min)?)?$}) { |m| ($1 || $4) ? ($2.to_i + $5.to_i / 60.0) : m[0] }
          end
          # 2,5 => 2.5
          s.gsub!(',', '.')
          begin; Kernel.Float(s); rescue; nil; end
        end
      end
    end
  end
end
