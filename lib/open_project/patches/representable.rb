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

require "representable"
require "open_project/patches"

module OpenProject::Patches::Representable
  module DecoratorPatch
    def self.included(base)
      base.class_eval do
        def self.as_strategy=(strategy)
          raise "The :as_strategy option should respond to #call?" unless strategy.respond_to?(:call)

          @as_strategy = strategy
        end

        def self.as_strategy
          @as_strategy
        end

        def self.property(name, options = {}, &)
          # Note: `:writeable` is required by declarative gem
          options[:writeable] = options.delete :writable if options.has_key?(:writable)
          options = { as: as_strategy.call(name.to_s) }.merge(options) if as_strategy

          super
        end
      end
    end
  end

  module OverwriteOnNilPatch
    def self.included(base)
      base.class_eval do
        unless const_defined?(:OverwriteOnNil)
          raise "Missing OverwriteOnNil on Representable gem, check if this patch still applies"
        end

        remove_const :OverwriteOnNil

        ##
        # Redefine OverwriteOnNil to ensure we use the correct setter
        # https://github.com/trailblazer/representable/issues/234
        const_set(:OverwriteOnNil, ->(input, *) { input })
      end
    end
  end
end

OpenProject::Patches.patch_gem_version "representable", "3.2.0" do
  unless Representable::Decorator.included_modules.include?(OpenProject::Patches::Representable::DecoratorPatch)
    Representable::Decorator.include OpenProject::Patches::Representable::DecoratorPatch
  end

  unless Representable::Decorator.included_modules.include?(OpenProject::Patches::Representable::OverwriteOnNilPatch)
    Representable.include OpenProject::Patches::Representable::OverwriteOnNilPatch
  end
end
