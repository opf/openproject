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

class AddLabelsToAllForms < ActiveRecord::Migration[8.1]
  class MigratedGroup < ActiveRecord::Base
    self.table_name = "form_configuration_groups"
  end

  class MigratedAttribute < ActiveRecord::Base
    self.table_name = "form_configuration_attributes"
  end

  def up
    forms_with_labels = MigratedAttribute.where(attribute_key: "labels").select(:form_configuration_id)

    MigratedGroup
      .where(default_key: "details")
      .where.not(form_configuration_id: forms_with_labels)
      .find_each { |details_group| append_labels(details_group) }
  end

  def down; end

  private

  def append_labels(group)
    last_position = MigratedAttribute.where(form_configuration_group_id: group.id).maximum(:position) || 0

    MigratedAttribute.create!(form_configuration_id: group.form_configuration_id,
                              form_configuration_group_id: group.id,
                              position: last_position + 1,
                              attribute_key: "labels")
  end
end
