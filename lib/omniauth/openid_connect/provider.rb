#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module OmniAuth
  module OpenIDConnect
    class Provider
      def self.inherited(subclass)
        all << subclass
      end

      def self.all
        @providers ||= Set.new
      end

      def self.load_generic_providers
        providers = configs.reject do |pro, config|
          all.any? { |p| p.provider_name == pro }
        end

        providers.each do |name, config|
          host = config["host"] || URI.parse(config["authorization_endpoint"]).host

          if host
            create(name, host)
          else
            Rails.logger.warn("No host configured for generic provider '#{provider_name}'.")
          end
        end
      end

      def self.create(name, host_name)
        klass = Class.new(Provider)

        klass.send :define_method, :host do
          host_name
        end

        OmniAuth::OpenIDConnect.const_set(name.camelize.classify, klass)

        klass
      end

      def self.available
        all.select(&:available?)
      end

      def self.unavailable
        all.reject(&:available?)
      end

      def self.available?
        !!config["secret"] && !!config["identifier"]
      end

      def self.provider_name
        self.name.demodulize.downcase
      end

      def self.config
        Hash(configs[provider_name])
      end

      def self.configs
        from_settings = if Setting.plugin_openproject_openid_connect.is_a? Hash
          Hash(Setting.plugin_openproject_openid_connect["providers"])
        else
          {}
        end
        # Settings override configuration.yml
        Hash(OpenProject::Configuration["openid_connect"]).deep_merge(from_settings)
      end

      def to_hash
        options
      end

      def name
        self.class.provider_name
      end

      def options
        {
          :name => name,
          :scope => [:openid, :email, :profile],
          :icon => config["icon"],
          :display_name => config["display_name"],
          :client_options => client_options.merge( # override with configuration
            Hash[
              config.reject do |key, value|
                ["identifier", "secret", "icon", "display_name"].include? key
              end.map do |key, value|
                [key.to_sym, value]
              end
            ]
          )
        }
      end

      def client_options
        {
          :port => 443,
          :scheme => "https",
          :host => host,
          :identifier => identifier,
          :secret => secret,
          :redirect_uri => redirect_uri
        }
      end

      def host
        raise NotImplemented("Host required")
      end

      def identifier
        config("identifier")
      end

      def secret
        config("secret")
      end

      def config(key = nil)
        return self.class.config unless key

        self.class.config[key] || error_configure(key)
      end

      ##
      # Path to which to redirect after successful authentication with the provider.
      def redirect_path
        "/auth/#{self.class.provider_name}/callback"
      end

      def redirect_uri
        "#{Setting.protocol}://#{Setting.host_name}#{redirect_path}"
      end

      private

      def error_configure(name)
        msg = <<-MSG
              Please configure #{name} in configuration.yml like this:

              openid_connect:
                #{self.class.provider_name}:
                  #{name}: <value>

              You can also configure it in Settings["plugin_openproject_openid_connect"]["providers"]
              in form of a hash analog to the yaml configuration shown above.
        MSG
        raise ArgumentError, msg.strip
      end
    end
  end
end
