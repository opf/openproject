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

module Report::Validation
  include Report::QueryUtils

  def register_validations(*validation_methods)
    validation_methods.flatten.each do |val_method|
      register_validation(val_method)
    end
  end

  def register_validation(val_method)
    const_name = val_method.to_s.camelize
    begin
      val_module = Report::Validation.const_get const_name
      singleton_class.send(:include, val_module)
      val_method = "validate_" + val_method.to_s.pluralize
      if method(val_method)
        validations << val_method
      else
        warn "#{val_module.name} does not define #{val_method}"
      end
    rescue NameError
      warn "No Module Report::Validation::#{const_name} found to validate #{val_method}"
    end
    self
  end

  def errors
    @errors ||= Hash.new { |h, k| h[k] = [] }
  end

  def validations
    @validations ||= []
  end

  def validate(*values)
    errors.clear
    return true if validations.empty?

    validations.all? do |validation|
      values.empty? ? true : send(validation, *values)
    end
  end
end
