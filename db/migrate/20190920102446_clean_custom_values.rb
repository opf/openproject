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

class CleanCustomValues < ActiveRecord::Migration[5.2]
  def up
    invalid_cv = CustomValue
      .joins(:custom_field)
      .where("#{CustomField.table_name}.field_format = 'list'")
      .where.not(value: "")
      .where("value !~ '^[0-9]+$'")

    if invalid_cv.count > 0
      warn_string = "Replacing invalid list custom values:\n"
      invalid_cv.pluck(:customized_type, :customized_id, :value).each do |customized_type, customized_id, value|
        warn_string << "- #{customized_type} ##{customized_id}: Value was #{value.inspect}\n"
      end

      warn warn_string
      invalid_cv.update_all(value: "")
    end
  end

  def down
    # This migration does not restore data
  end
end
