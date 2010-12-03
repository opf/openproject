# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

require 'blankslate'

module Redmine
  module Views
    module Builders
      class Structure < BlankSlate
        def initialize
          @struct = [{}]
        end
        
        def array(tag, &block)
          @struct << []
          block.call(self)
          ret = @struct.pop
          @struct.last[tag] = ret
        end
        
        def method_missing(sym, *args, &block)
          if args.any?
            if args.first.is_a?(Hash)
              if @struct.last.is_a?(Array)
                @struct.last << args.first
              else
                @struct.last[sym] = args.first
              end
            else
              if @struct.last.is_a?(Array)
                @struct.last << (args.last || {}).merge(:value => args.first)
              else
                @struct.last[sym] = args.first
              end
            end
          end
          
          if block
            @struct << {}
            block.call(self)
            ret = @struct.pop
            if @struct.last.is_a?(Array)
              @struct.last << ret
            else
              @struct.last[sym] = ret
            end
          end
        end
        
        def output
          raise "Need to implement #{self.class.name}#output"
        end
      end
    end
  end
end
