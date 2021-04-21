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

module Settings
  class Definition
    attr_accessor :name,
                  :format,
                  :value,
                  :api_name,
                  :serialized,
                  :api,
                  :admin,
                  :writable

    def initialize(name, format:, value:, api_name: name, serialized: false, api: true, admin: true, writable: true)
      self.name = name.to_s
      self.format = format.to_s
      self.value = value
      self.api_name = api_name
      self.serialized = serialized
      self.api = api
      self.admin = admin
      self.writable = writable
    end

    def serialized?
      !!serialized
    end

    def api?
      !!api
    end

    def admin?
      !!admin
    end

    def writable?
      !!writable
    end

    class << self
      def add(name, value:, format: nil, api_name: name, serialized: false, api: true, admin: true, writable: true)
        return if @by_name.present? && @by_name[name.to_s].present?

        @by_name = nil

        all << new(name,
                   format: format,
                   value: value,
                   api_name: api_name,
                   serialized: serialized,
                   api: api,
                   admin: admin,
                   writable: writable)
      end

      def define(&block)
        instance_exec(&block)
      end

      def [](name)
        @by_name ||= all.group_by(&:name).transform_values(&:first)

        @by_name[name.to_s]
      end

      def all
        @all ||= []

        unless loaded
          self.loaded = true
          require_relative 'definitions'

          load_config_from_file
        end

        @all
      end

      def add_key_value(key, value)
        format = case value
                 when TrueClass, FalseClass
                   :boolean
                 when Integer, Date, DateTime
                   value.class.name.downcase.to_sym
                 end

        add key,
            format: format,
            value: value,
            api: false,
            admin: true,
            writable: false
      end

      def load_config_from_file
        filename = Rails.root.join('config/configuration.yml')

        if File.file?(filename)
          file_config = YAML::load(ERB.new(File.read(filename)).result)

          if file_config.is_a? Hash
            load_env_from_config(file_config, Rails.env)
          else
            warn "#{filename} is not a valid OpenProject configuration file, ignoring."
          end
        end
      end

      def load_env_from_config(config, env)
        config['default']&.each do |name, value|
          override_value(name, value)
        end
        config[env]&.each do |name, value|
          override_value(name, value)
        end
      end

      private

      def override_value(name, value)
        if self[name]
          self[name].value = value
        else
          add_key_value(name, value)
        end
      end

      attr_accessor :loaded
    end
  end
end
