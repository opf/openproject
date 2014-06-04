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
    def self.included(base)
      base.class_eval do
        initializer "#{engine_name}.middleware" do |app|
          init_auth

          strategies = omniauth_strategies
          providers = lambda do |strategy|
            lambda { providers_for_strategy(strategy) }
          end

          app.config.middleware.use OmniAuth::FlexibleBuilder do
            strategies.each do |strategy|
              provider strategy, :providers => providers.call(strategy)
            end
          end
        end
      end
    end

    def init_auth; end

    def omniauth_strategies
      raise "subclass responsiblity"
    end

    def providers_for_strategy(strategy)
      raise "subclass responsiblity"
    end
  end
end
