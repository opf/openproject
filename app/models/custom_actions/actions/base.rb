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

class CustomActions::Actions::Base
  attr_reader :values

  DEFAULT_PRIORITY = 100

  def initialize(values = [])
    self.values = values
  end

  def values=(values)
    @values = Array(values)
  end

  def allowed_values
    raise NotImplementedError
  end

  def type
    raise NotImplementedError
  end

  def apply(_work_package)
    raise NotImplementedError
  end

  def human_name
    WorkPackage.human_attribute_name(self.class.key)
  end

  def self.key
    raise NotImplementedError
  end

  def self.all
    [self]
  end

  def self.for(key)
    if key == self.key
      self
    end
  end

  def key
    self.class.key
  end

  def required?
    false
  end

  def multi_value?
    false
  end

  def validate(errors)
    validate_value_required(errors)
    validate_only_one_value(errors)
  end

  def priority
    DEFAULT_PRIORITY
  end

  private

  def validate_value_required(errors)
    if required? && values.empty?
      errors.add :actions,
                 :empty,
                 name: human_name
    end
  end

  def validate_only_one_value(errors)
    if !multi_value? && values.length > 1
      errors.add :actions,
                 :only_one_allowed,
                 name: human_name
    end
  end
end
