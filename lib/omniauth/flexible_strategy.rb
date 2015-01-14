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

require 'open_project/plugins/auth_plugin'

module OmniAuth
  module FlexibleStrategyClass
    def new(app, *args, &block)
      super(app, *args, &block).tap do |strategy|
        strategy.extend FlexibleStrategy
      end
    end
  end

  module FlexibleStrategy
    def on_auth_path?
      !not_on_auth_path? && (match_provider! || false) && super
    end

    ##
    # Tries to match the request path of the current request with one of the registered providers.
    # If a match is found the strategy is intialised with that provider to handle the request.
    def match_provider!
      return false unless @providers

      @provider = providers.find do |p|
        (current_path =~ /#{path_for_provider(p.to_hash[:name])}/) == 0
      end

      if @provider
        options.merge! provider.to_hash
      end

      @provider
    end

    def omniauth_hash_to_user_attributes(auth)
      if options.key?(:openproject_attribute_map)
        options[:openproject_attribute_map].call(auth)
      else
        {}
      end
    end

    def path_for_provider(name)
      "#{path_prefix}/#{name}"
    end

    ##
    # This method returning false does not mean that the current request should be handled by
    # this strategy. The method can, however, indicate that a request should NOT be handled by it.
    # In which case it returns true.
    def not_on_auth_path?
      (current_path =~ /#{path_prefix}/) != 0
    end

    def providers
      @providers ||= OpenProject::Plugins::AuthPlugin.providers_for(self.class)
    end

    def provider
      @provider
    end

    def providers=(providers)
      @providers = providers
    end

    def dup
      super.tap do |s|
        s.extend FlexibleStrategy
        s.providers = providers
      end
    end
  end
end
