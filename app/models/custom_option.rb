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

##
# A custom option is a possible value for a given custom field
# which is restricted to a set of specific values.
class CustomOption < ApplicationRecord
  belongs_to :custom_field, touch: true

  validates :value, presence: true, length: { maximum: 255 }

  before_destroy :assure_at_least_one_option

  def to_s
    value
  end

  alias :name :to_s

  protected

  def assure_at_least_one_option
    return if CustomOption.where(custom_field_id:).where.not(id:).count > 0

    errors.add(:base, I18n.t(:"activerecord.errors.models.custom_field.at_least_one_custom_option"))

    throw :abort
  end
end
