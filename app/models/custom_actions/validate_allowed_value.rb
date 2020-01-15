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
# See docs/COPYRIGHT.rdoc for more details.
#++

module CustomActions::ValidateAllowedValue
  private

  def validate_allowed_value(errors, attribute)
    return unless values.any?

    allowed_ids = allowed_values.map { |v| v[:value] }
    if values.to_set != (allowed_ids & values).to_set
      errors.add attribute,
                 I18n.t(:'activerecord.errors.models.custom_actions.inclusion', name: human_name),
                 error_symbol: :inclusion
    end
  end
end
