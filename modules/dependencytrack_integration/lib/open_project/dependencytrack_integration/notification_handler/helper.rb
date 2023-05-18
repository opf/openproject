#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2021 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::DependencytrackIntegration
    module NotificationHandler
      module Helper
    
        ##
        # A wapper around a ruby Hash to access webhook payloads.
        # All methods called on it are converted to `.fetch` hash-access, raising an error if the string-key does not exist.
        # If the method ends with a question mark, e.g. "comment?" not error is raised if the key does not exist.
        # If the fetched value is again a hash, the value is wrapped into a new payload object.
        class Payload
          def initialize(payload)
            @payload = payload
          end
  
          def to_h
            @payload.dup
          end
  
          def method_missing(name, *args, &block)
            super unless args.empty? && block.nil?
  
            value = if name.end_with?('?')
                      @payload.fetch(name.to_s[..-2], nil)
                    else
                      @payload.fetch(name.to_s)
                    end
  
            return Payload.new(value) if value.is_a?(Hash)
  
            value
          end
  
          def respond_to_missing?(_method_name, _include_private = false)
            true
          end
        end
  
        def wrap_payload(payload)
          Payload.new(payload)
        end
  
      end
    end
  end