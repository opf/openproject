#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Macros::Internal
  class MacroRegistry
    require 'open_project/text_formatting/macros/macro_base'
    require 'open_project/text_formatting/macros/macro_descriptor'
    require 'open_project/text_formatting/macros/internal/registered_macro'

    # NOTE: we need to get rid of these as soon as legacy macro syntax has been eliminated
    require 'open_project/text_formatting/macros/internal/legacy_support_macro_descriptor'
    require 'open_project/text_formatting/macros/internal/legacy_macro_base'
    require 'open_project/text_formatting/macros/internal/registered_legacy_support_macro'
    require 'open_project/text_formatting/macros/internal/registered_legacy_macro'

    include Singleton

    # Registers the specified new style macro class
    def register(macro)
      registered_macro = OpenProject::TextFormatting::Macros::Internal::RegisteredMacro.new(macro)
      register0 registered_macro
      if macro.descriptor.legacy_support?
        register0 OpenProject::TextFormatting::Macros::Internal::RegisteredLegacySupportMacro
                    .new(registered_macro)
      end
    end

    # Registers the specified legacy style macro
    # that we must get rid of once legacy macros have been eliminated
    def register_legacy(id, desc, block)
      register0 OpenProject::TextFormatting::Macros::Internal::RegisteredLegacyMacro.new(
        id, desc, block
      )
    end

    def registered?(qname)
      !@registered_macros[qname].nil?
    end

    def find(qname)
      @registered_macros[qname]
    end

    def registered_macros
      result = []
      @registered_macros.each_value do |macro|
        result << macro.descriptor
      end
      result
    end

    private

    def initialize
      @registered_macros = {}
    end

    def register0(macro)
      # TODO:coy:error handling:duplicate registration
      @registered_macros[macro.descriptor.qname] = macro
    end
  end
end
