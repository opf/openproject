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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Base for formatters rendering the change to a set of associated records
# referenced by the journable. Each value is the sorted, comma-joined ids;
# deleted or non-visible records are dropped.
class OpenProject::JournalFormatter::JoinedAssociation < JournalFormatter::NamedAssociation
  private

  def format_values(values, key)
    klass = class_from_field(key)

    values.map do |value|
      next if value.blank? || klass.nil?

      value.to_s.split(",")
           .filter_map { |id| name_or_placeholder(associated_object(klass, id.to_i)) }
           .join(", ")
           .presence
    end
  end
end
