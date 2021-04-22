#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module AccessControl
    class Permission
      attr_reader :name,
                  :controller_actions,
                  :contract_actions,
                  :project_module,
                  :dependencies

      def initialize(name, hash, options)
        @name = name
        @controller_actions = []
        @public = options[:public] || false
        @require = options[:require]
        @global = options[:global] || false
        @enabled = options.include?(:enabled) ? options[:enabled] : true
        @dependencies = Array(options[:dependencies]) || []
        @project_module = options[:project_module]
        @contract_actions = options[:contract_actions] || []
        hash.each do |controller, actions|
          @controller_actions << if actions.is_a? Array
                                   actions.map { |action| "#{controller}/#{action}" }
                                 else
                                   "#{controller}/#{actions}"
                                 end
        end
        @controller_actions.flatten!
      end

      def public?
        @public
      end

      def global?
        @global
      end

      def require_member?
        @require && @require == :member
      end

      def require_loggedin?
        @require && (@require == :member || @require == :loggedin)
      end

      def enabled?
        if @enabled.respond_to?(:call)
          @enabled.call
        else
          @enabled
        end
      end
    end
  end
end
