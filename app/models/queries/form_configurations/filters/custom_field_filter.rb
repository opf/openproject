# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::FormConfigurations::Filters::CustomFieldFilter < Queries::Filters::Base
  self.model = FormConfiguration

  def self.key
    :custom_field_id
  end

  def type
    :list
  end

  def type_strategy
    @type_strategy ||= ::Queries::Filters::Strategies::IntegerList.new(self)
  end

  def human_name
    WorkPackageCustomField.model_name.human
  end

  def where
    ["form_configurations.id IN (?)", custom_field.form_configurations.select(:id)]
  end

  private

  def custom_field
    WorkPackageCustomField.find(values.first)
  end
end
