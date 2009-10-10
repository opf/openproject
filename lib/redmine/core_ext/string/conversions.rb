# redMine - project management software
# Copyright (C) 2008  Jean-Philippe Lang
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

module Redmine #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      # Custom string conversions
      module Conversions
        # Parses hours format and returns a float
        def to_hours
          s = self.dup
          s.strip!
          if s =~ %r{^(\d+([.,]\d+)?)h?$}
            s = $1
          else
            # 2:30 => 2.5
            s.gsub!(%r{^(\d+):(\d+)$}) { $1.to_i + $2.to_i / 60.0 }
            # 2h30, 2h, 30m => 2.5, 2, 0.5
            s.gsub!(%r{^((\d+)\s*(h|hours?))?\s*((\d+)\s*(m|min)?)?$}) { |m| ($1 || $4) ? ($2.to_i + $5.to_i / 60.0) : m[0] }
          end
          # 2,5 => 2.5
          s.gsub!(',', '.')
          begin; Kernel.Float(s); rescue; nil; end
        end
        
        # Object#to_a removed in ruby1.9
        if RUBY_VERSION > '1.9'
          def to_a
            [self.dup]
          end
        end
      end
    end
  end
end
