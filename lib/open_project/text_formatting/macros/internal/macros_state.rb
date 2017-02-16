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
  # Simple state holder for stateful macros built upon RequestStore.
  #
  # All macro state is stored under the key `:macros_state`, with individual macro state being
  # stored under the macro's respective `qname`, e.g. `opf:toc`.
  #
  class MacrosState
    include Singleton

    #
    # Returns a copy of the currently stored state or a new empty state.
    #
    # @return Hash
    #
    def get_or_create(descriptor)
      macro_state = RequestStore.store[:macros_state] ||= {}
      qname = descriptor.qname.to_sym
      (macro_state[qname] ||= {}).dup
    end

    #
    # Stores a copy of the current state.
    #
    def set_state(descriptor, state)
      macro_state = RequestStore.store[:macros_state] ||= {}
      macro_state[descriptor.qname.to_sym] = state.dup
    end
  end
end
