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

module API
  module V3
    module Settings
      class SettingsRepresenter < ::API::Decorators::Single
        def _type
          'Settings'
        end

        link :self do
          {
            href: api_v3_paths.settings,
            title: I18n.t(:label_setting_plural)
          }
        end

        Setting.available_settings.each do |name, config|
          #next unless config['format'] == 'boolean'

          property name,
                   getter: ->(*) {
                     Setting[name]
                   }
        end

        property :updatedAt,
                 getter: ->(represented:, decorator:, **) {
                   decorator.datetime_formatter.format_datetime(Setting.maximum(:updated_at), allow_nil: true)
                 }


        def model_required?
          false
        end
      end
    end
  end
end
