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
          builder.strategies.each do |strategy, providers|
            provider strategy, :providers => providers
          end
        end
      end
    end
  end

  class ProviderBuilder
    def strategy(key, &providers)
      strategies[key] = providers
    end

    def strategies
      @strategies ||= {}
    end
  end
end
