#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
module JournalChanges
  def get_changes
    return {} if data.nil?
    return @changes if @changes

    @changes = HashWithIndifferentAccess.new

    if predecessor.nil?
      @changes = data.journaled_attributes.select { |_, v| !v.nil? }
                   .inject({}) { |h, (k, v)| h[k] = [nil, v]; h }
    else
      normalized_data = JournalManager.normalize_newlines(data.journaled_attributes)
      normalized_predecessor_data = JournalManager.normalize_newlines(predecessor.data.journaled_attributes)

      normalized_data.select do |k, v|
        # we dont record changes for changes from nil to empty strings and vice versa
        pred = normalized_predecessor_data[k]
        v != pred && (v.present? || pred.present?)
      end.each do |k, v|
        @changes[k] = [normalized_predecessor_data[k], v]
      end
    end

    @changes.merge!(get_association_changes predecessor, 'attachable', 'attachments', :attachment_id, :filename)
    @changes.merge!(get_association_changes predecessor, 'customizable', 'custom_fields', :custom_field_id, :value)
  end

  def get_association_changes(predecessor, journal_association, association, key, value)
    changes = {}
    journal_assoc_name = "#{journal_association}_journals"

    if predecessor.nil?
      send(journal_assoc_name).each_with_object(changes) { |a, h| h["#{association}_#{a.send(key)}"] = [nil, a.send(value)] }
    else
      current = send(journal_assoc_name).map(&:attributes)
      predecessor_journals = predecessor.send(journal_assoc_name).map(&:attributes)

      merged_journals = JournalManager.merge_reference_journals_by_id current,
                                                                      predecessor_journals,
                                                                      key.to_s

      changes.merge! JournalManager.added_references(merged_journals, association, value.to_s)
      changes.merge! JournalManager.removed_references(merged_journals, association, value.to_s)
      changes.merge! JournalManager.changed_references(merged_journals, association, value.to_s)
    end

    changes
  end
end
