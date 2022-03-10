# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module CustomActions::Actions::Strategies::Boolean
  include CustomActions::ValidateAllowedValue

  def allowed_values
    [
      { label: I18n.t(:general_text_yes), value: OpenProject::Database::DB_VALUE_TRUE },
      { label: I18n.t(:general_text_no), value: OpenProject::Database::DB_VALUE_FALSE }
    ]
  end

  def type
    :boolean
  end

  def validate(errors)
    validate_allowed_value(errors, :actions)
    super
  end
end
