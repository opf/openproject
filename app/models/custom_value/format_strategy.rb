#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class CustomValue::FormatStrategy
  attr_reader :custom_value

  delegate :custom_field, :value, to: :custom_value

  def initialize(custom_value)
    @custom_value = custom_value
  end

  delegate :present?, to: :value, prefix: true

  # Returns the value of the CustomValue in a typed fashion (i.e. not as the string
  # that is used for representation in the database)
  def typed_value
    raise 'SubclassResponsibility'
  end

  # Returns the value of the CustomValue formatted to a string
  # representation.
  def formatted_value
    value.to_s
  end

  # Parses the value to
  # 1) have a unified representation for different inputs
  # 2) memoize typed values (if the subclass decides to do so
  def parse_value(val)
    self.memoized_typed_value = nil

    val
  end

  # Validates the type of the custom field and returns a symbol indicating the validation error
  # if an error occurred; returns nil if no error occurred
  def validate_type_of_value
    raise 'SubclassResponsibility'
  end

  private

  attr_accessor :memoized_typed_value
end
