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

module Redmine
  module Activity
    mattr_accessor :available_event_types, :default_event_types, :providers

    @@available_event_types = []
    @@default_event_types = []
    @@providers = Hash.new { |h, k| h[k] = [] }

    class << self
      def map(&_block)
        yield self
      end

      # Registers an activity provider
      def register(event_type, options = {})
        options.assert_valid_keys(:class_name, :default)

        event_type = event_type.to_s
        providers = options[:class_name] || event_type.classify
        providers = ([] << providers) unless providers.is_a?(Array)

        @@available_event_types << event_type unless @@available_event_types.include?(event_type)
        @@default_event_types << event_type unless @@default_event_types.include?(event_type) || options[:default] == false
        @@providers[event_type] += providers
      end
    end
  end
end
