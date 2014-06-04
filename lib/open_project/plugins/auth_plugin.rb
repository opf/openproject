#-- copyright
# OpenProject AuthPlugins
#
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::Plugins
  module AuthPlugin
    def register_auth_providers(&build_providers)
      initializer "#{engine_name}.middleware" do |app|
        builder = ProviderBuilder.new
        builder.instance_eval(&build_providers)

        app.config.middleware.use OmniAuth::FlexibleBuilder do
          AuthPlugin.strategies.each do |strategy, providers|
            provider strategy
          end
        end
      end
    end

    def self.strategies
      @strategies ||= {}
    end

    def self.providers_for(strategy)
      strategies[strategy_key(strategy)].map(&:call).flatten.map { |p| p.to_hash }
    end

    def self.providers
      strategies.values.flatten.map(&:call).flatten.map { |p| p.to_hash }
    end

    def self.strategy_key(strategy)
      return strategy if strategy.is_a? Symbol

      name = strategy.name.demodulize
      camelization = OmniAuth.config.camelizations.select do |k, v|
        v == name
      end.take(1).map do |k, v|
        k
      end.first

      [camelization, name].compact.first.underscore.to_sym
    end
  end

  class ProviderBuilder
    def strategy(strategy, &providers)
      key = AuthPlugin.strategy_key(strategy)
      if AuthPlugin.strategies.include? key
        AuthPlugin.strategies[key] << providers
      else
        AuthPlugin.strategies[key] = [providers]
      end
    end
  end
end
