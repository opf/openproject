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

module OpenProject
  module SCM
    class Manager
      class << self
        def registered
          @scms ||= {
            subversion: ::Repository::Subversion,
            git: ::Repository::Git
          }
        end

        ##
        # Returns a list of registered SCM vendor symbols
        # (e.g., :git, :subversion)
        def vendors
          @scms.keys
        end

        ##
        # Returns all enabled repositories as a Hash
        # { vendor_name: repository class constant }
        def enabled
          registered.select { |vendor, _| Setting.enabled_scm.include?(vendor.to_s) }
        end

        ##
        # Returns whether the particular vendor symbol
        # is available AND enabled through settings.
        def enabled?(vendor)
          enabled.include?(vendor)
        end

        # Return all manageable vendors
        def manageable
          registered.select { |_, klass| klass.manageable? }
        end

        ##
        # Return a hash of all managed paths for SCM vendors
        # { Vendor: <Path> }
        def managed_paths
          paths = {}
          registered.each do |vendor, klass|
            paths[vendor] = klass.managed_root if klass.manageable?
          end

          paths
        end

        # Add a new SCM adapter and repository
        def add(vendor)
          # Force model lookup to avoid
          # const errors later on.
          klass = Repository.const_get(vendor.to_s.camelize)
          registered[vendor] = klass
        end

        # Remove a SCM adapter from Redmine's list of supported scms
        delegate :delete, to: :registered
      end
    end
  end
end
