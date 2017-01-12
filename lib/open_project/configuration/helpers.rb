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

module OpenProject
  module Configuration
    ##
    # To be included into OpenProject::Configuration in order to provide
    # helper methods for easier access to certain configuration options.
    module Helpers

      ##
      # Carrierwave storage type. Possible values are, among others, :file and :fog.
      # The latter requires further configuration.
      def attachments_storage
        (self['attachments_storage'] || 'file').to_sym
      end

      def attachments_storage_path
        Rails.root.join(self['attachments_storage_path'] || 'files')
      end

      def fog_credentials
        Hash[(Hash(self['fog'])['credentials'] || {}).map { |key, value| [key.to_sym, value] }]
      end

      def fog_directory
        Hash(self['fog'])['directory']
      end

      def file_uploader
        available_file_uploaders[OpenProject::Configuration.attachments_storage.to_sym]
      end

      def hidden_menu_items
        menus = self['hidden_menu_items'].map { |label, nodes|
          [label, array(nodes)]
        }

        Hash[menus]
      end

      def disabled_modules
        array self['disabled_modules']
      end

      def blacklisted_routes
        array self['blacklisted_routes']
      end

      def available_file_uploaders
        uploaders = {
          file: ::LocalFileUploader
        }

        # Do not load Fog uploader unless configured,
        # it will fail with missing configuration
        unless OpenProject::Configuration.fog_credentials.empty?
          uploaders[:fog] = '::FogFileUploader'.constantize
        end

        uploaders
      end

      private

      ##
      # Yields the given configuration value as an array.
      # Either the value already is an array or a string with values separated by spaces.
      # In the latter case the string will be split and the values returned as an array.
      def array(value)
        if value =~ / /
          value.split ' '
        else
          Array(value)
        end
      end
    end
  end
end
