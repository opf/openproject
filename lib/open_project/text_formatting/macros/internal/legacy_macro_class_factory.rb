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
  #
  # Factory for legacy macro classes
  #
  # NOTE: we must get rid of this of once legacy macros have been eliminated
  #
  class LegacyMacroClassFactory
    require 'open_project/text_formatting/macros/internal/legacy_macro_base'

    def self.create_new_class(id, desc, block)
      result = Class.new(LegacyMacroBase) do
        define_method :execute_legacy, block

        descriptor {
          prefix  :legacy
          id      id
          desc    desc
          legacy
        }

        # will be registered using a different mechanism,
        # @see OpenProject::TextFormatting::Macros::MacroRegistry#register_legacy
        # @see Redmine::WikiFormatting::Macros.macro
        # register!
      end
      result
    end
  end
end
