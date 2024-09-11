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

module CustomActions::Actions::Strategies::Associated
  include CustomActions::ValidateAllowedValue
  include CustomActions::ValuesToInteger

  def allowed_values
    @allowed_values ||= begin
      options = associated
                .map { |value, label| { value:, label: } }

      if required?
        options
      else
        options.unshift(value: nil, label: I18n.t("placeholders.default"))
      end
    end
  end

  def apply(work_package)
    work_package.send(:"#{key}_id=", values.first)
  end

  def type
    :associated_property
  end

  def associated
    raise "Not implemented error"
  end

  def validate(errors)
    validate_allowed_value(errors, :actions)
    super
  end
end
