#-- copyright
# OpenProject Reporting Plugin
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


require_dependency 'open_project/configuration'

module OpenProject::Reporting::Patches
  module OpenProject::ConfigurationPatch
    def self.included(base)
      base.class_eval do
        extend ModuleMethods

        @defaults['cost_reporting_cache_filter_classes'] = true

        if config_loaded_before_patch?
          @config['cost_reporting_cache_filter_classes'] = true
        end
      end
    end

    module ModuleMethods
      def config_loaded_before_patch?
        @config.present? && !@config.has_key?('cost_reporting_cache_filter_classes')
      end

      def cost_reporting_cache_filter_classes
        @config['cost_reporting_cache_filter_classes']
      end
    end
  end
end
