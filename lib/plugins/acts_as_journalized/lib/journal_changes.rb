#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
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

module JournalChanges
  def get_changes
    return @changes if @changes
    return {} if data.nil?

    @changes = HashWithIndifferentAccess.new

    if predecessor.nil?
      @changes = data.journaled_attributes
                 .reject { |_, new_value| new_value.nil? }
                 .inject({}) { |result, (attribute, new_value)|
                   result[attribute] = [nil, new_value]
                   result
                 }
    else
      normalized_new_data = JournalManager.normalize_newlines(data.journaled_attributes)
      normalized_old_data = JournalManager.normalize_newlines(predecessor.data.journaled_attributes)

      normalized_new_data.select { |attribute, new_value|
        # we dont record changes for changes from nil to empty strings and vice versa
        old_value = normalized_old_data[attribute]
        new_value != old_value && (new_value.present? || old_value.present?)
      }.each do |attribute, new_value|
        @changes[attribute] = [normalized_old_data[attribute], new_value]
      end
    end

    @changes.merge!(get_association_changes(predecessor, 'attachable', 'attachments', :attachment_id, :filename))
    @changes.merge!(get_association_changes(predecessor, 'customizable', 'custom_fields', :custom_field_id, :value))
  end

  def get_association_changes(predecessor, journal_association, association, key, value)
    journal_assoc_name = "#{journal_association}_journals"

    if predecessor.nil?
      send(journal_assoc_name).each_with_object({}) do |associated_journal, h|
        changed_attribute = "#{association}_#{associated_journal.send(key)}"
        new_value = associated_journal.send(value)
        h[changed_attribute] = [nil, new_value]
      end
    else
      new_journals = send(journal_assoc_name).map(&:attributes)
      old_journals = predecessor.send(journal_assoc_name).map(&:attributes)

      JournalManager.changes_on_association(new_journals, old_journals, association, key, value)
    end
  end
end
