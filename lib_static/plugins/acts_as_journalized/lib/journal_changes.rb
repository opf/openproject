#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module JournalChanges
  def get_changes
    return @changes if @changes
    return {} if data.nil?

    @changes = ::Acts::Journalized::JournableDiffer.changes(predecessor&.data, data)

    @changes[:cause] = [nil, cause] if cause.present?

    if journable&.attachable?
      @changes.merge!(
        ::Acts::Journalized::JournableDiffer.association_changes(
          predecessor,
          self,
          'attachable_journals',
          'attachments',
          :attachment_id,
          :filename
        )
      )
    end

    if journable&.customizable?
      @changes.merge!(
        ::Acts::Journalized::JournableDiffer.association_changes(
          predecessor,
          self,
          'customizable_journals',
          'custom_fields',
          :custom_field_id,
          :value
        )
      )
    end

    if has_file_links?
      @changes.merge!(
        ::Acts::Journalized::FileLinkJournalDiffer.get_changes_to_file_links(
          predecessor,
          storable_journals
        )
      )
    end

    @changes
  end
end
