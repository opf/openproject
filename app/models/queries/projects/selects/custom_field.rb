# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Queries::Projects::Selects::CustomField < Queries::Selects::Base
  validates :custom_field, presence: { message: I18n.t(:'activerecord.errors.messages.does_not_exist') }

  def self.key
    /cf_(\d+)/
  end

  def self.available?
    EnterpriseToken.allows_to?(:custom_fields_in_projects_list)
  end

  def self.all_available
    return [] unless available?

    ProjectCustomField
      .visible
      .pluck(:id)
      .map { |cf_id| new(:"cf_#{cf_id}") }
  end

  def caption
    custom_field.name
  end

  def custom_field
    @custom_field ||= ProjectCustomField
                        .visible
                        .find_by(id: self.class.key.match(attribute)[1])
  end
end
