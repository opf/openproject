#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Scm
    class Manager
      class << self
        def registered
          @scms ||= {}
        end

        def vendors
          @scms.keys
        end

        ##
        # Returns all enabled repositories as a Hash
        # { vendor_name: repository class constant }
        def enabled
          registered.select { |scm| Setting.enabled_scm.include?(scm) }
        end

        # Return all manageable vendors
        def manageable
          enabled.select { |_, vendor| vendor.manageable? }.keys
        end

        ##
        # Return a hash of all managed paths for SCM vendors
        # { Vendor: <Path> }
        def managed_paths
          paths = {}
          @scms.each do |vendor, klass|
            paths[vendor] = klass.managed_root if klass.manageable?
          end

          paths
        end

        # Add a new SCM adapter and repository
        def add(scm_name)
          # Force model lookup to avoid
          # const errors later on.
          klass = Repository.const_get(scm_name)
          registered[scm_name] = klass
        end

        # Remove a SCM adapter from Redmine's list of supported scms
        def delete(scm_name)
          registered.delete(scm_name)
        end
      end
    end
  end
end
