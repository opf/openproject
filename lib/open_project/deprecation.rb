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

module OpenProject::Deprecation
  class << self
    def deprecator
      @@deprecator ||= ActiveSupport::Deprecation
                        .new("in a future major upgrade", "OpenProject")
    end

    delegate :warn, to: :deprecator

    ##
    # Deprecate the given method with a notice regarding future removal
    #
    # @mod [Class] The module on which the method is to be replaced.
    # @method [:symbol] The method to replace.
    # @replacement [nil, :symbol, String] The replacement method.
    def deprecate_method(mod, method, replacement = nil)
      deprecator.deprecate_methods(mod, method => replacement)
    end

    ##
    # Deprecate the given class method with a notice regarding future removal
    #
    # @mod [Class] The module on which the method is to be replaced.
    # @method [:symbol] The method to replace.
    # @replacement [nil, :symbol, String] The replacement method.
    def deprecate_class_method(mod, method, replacement = nil)
      deprecate_method(mod.singleton_class, method, replacement)
    end

    def replaced(old_method, new_method, called_from)
      message = <<~MSG
        #{old_method} is deprecated and will be removed in a future OpenProject version.

        Please use #{new_method} instead.

      MSG

      ActiveSupport::Deprecation.warn message, called_from
    end
  end
end
