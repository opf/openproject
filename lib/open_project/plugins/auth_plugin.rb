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

module OpenProject::Plugins
  module AuthPlugin
    def register_auth_providers(&build_providers)
      initializer "#{engine_name}.middleware" do |app|
        builder = ProviderBuilder.new
        builder.instance_eval(&build_providers)

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
      strategies[strategy_key(strategy)].map(&:call).flatten.map(&:to_hash)
    end

    def self.providers
      strategies.values.flatten.map(&:call).flatten.map(&:to_hash)
    end

    def self.strategy_key(strategy)
      return strategy if strategy.is_a? Symbol

      name = strategy.name.demodulize
      camelization = OmniAuth.config.camelizations.select do |_k, v|
        v == name
      end.take(1).map do |k, _v|
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
        new_strategies << strategy
      end
    end

    def new_strategies
      @new_strategies ||= []
    end
  end
end
