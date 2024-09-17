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

module OpenProject::Plugins
  module AuthPlugin
    def register_auth_providers(&)
      initializer "#{engine_name}.middleware" do |app|
        builder = ProviderBuilder.new
        builder.instance_eval(&)

        app.config.middleware.use OmniAuth::FlexibleBuilder do
          builder.new_strategies.each do |strategy|
            provider strategy
          end
        end
      end
    end

    def self.strategies
      @strategies ||= {}
    end

    def self.providers_for(strategy)
      key = strategy_key(strategy)
      matching = Array(strategies[key])
      filtered_strategies(key, matching.map(&:call).flatten.map(&:to_hash))
    end

    def self.login_provider_for(user)
      return unless user.identity_url

      provider_name = user.identity_url.split(":").first
      find_provider_by_name(provider_name)
    end

    def self.find_provider_by_name(provider_name)
      providers.detect { |hash| hash[:name].to_s == provider_name.to_s }
    end

    def self.providers
      RequestStore.fetch(:openproject_omniauth_filtered_strategies) do
        strategies.flat_map do |strategy_key, values|
          filtered_strategies(strategy_key, values.flat_map(&:call).flat_map(&:to_hash))
        end
      end
    end

    def self.filtered_strategies(strategy_key, options)
      options.select do |provider|
        filtered = filtered_strategy?(strategy_key, provider)
        warn_unavailable(name) unless filtered

        filtered
      end
    end

    def self.filtered_strategy?(_strategy_key, provider)
      name = provider[:name]&.to_s
      !EnterpriseToken.show_banners? || name == "developer"
    end

    def self.strategy_key(strategy)
      return strategy if strategy.is_a? Symbol
      return strategy.to_sym if strategy.is_a? String

      name = strategy.name.demodulize
      camelization = OmniAuth.config.camelizations.select do |_k, v|
        v == name
      end.take(1).map do |k, _v|
        k
      end.first

      [camelization, name].compact.first.underscore.to_sym
    end

    ##
    # Indicates whether or not self registration should be limited for the provider
    # with the given name.
    #
    # @param provider [String] Name of the provider
    def self.limit_self_registration?(provider:)
      Hash(find_provider_by_name(provider))[:limit_self_registration]
    end

    def self.warn_unavailable(name)
      RequestStore.fetch("warn_unavailable_auth_#{name}") do
        Rails.logger.warn { "OmniAuth SSO strategy #{name} is only available for Enterprise Editions." }
        true
      end
    end
  end

  class ProviderBuilder
    def strategy(strategy, &providers)
      key = AuthPlugin.strategy_key(strategy)

      if AuthPlugin.strategies.include? key
        AuthPlugin.strategies[key] << providers
      else
        AuthPlugin.strategies[key] = [providers]
        new_strategies << strategy
      end
    end

    def new_strategies
      @new_strategies ||= []
    end
  end
end
