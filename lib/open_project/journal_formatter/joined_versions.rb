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

# Base for formatters rendering the change to a set of versions referenced by a
# work package. Each value is the sorted, comma-joined version ids (see
# JournalChanges); every id is resolved to the version's name, with a
# placeholder for versions that have been deleted or are no longer visible to
# the reader.
class OpenProject::JournalFormatter::JoinedVersions < JournalFormatter::NamedAssociation
  def render(key, values, options = { html: true })
    old_ids, new_ids = values.map { ids_from(it) }
    return super unless set_change?(old_ids, new_ids)
    return render_permission_denied_message(options) unless permission_granted?(options.merge(key:))

    render_set_change(key, old_ids, new_ids, options)
  end

  private

  def render_set_change(key, old_ids, new_ids, options)
    key = key.to_s
    label = set_change_label(key, options)
    added = change_names(new_ids - old_ids, key, options)
    removed = change_names(old_ids - new_ids, key, options)

    lines = []
    lines << I18n.t(:text_journal_set_added, label:, value: added) if added.present?
    lines << I18n.t(:text_journal_set_removed, label:, old: removed) if removed.present?
    lines.join(options[:html] ? "<br/>" : "\n")
  end

  def set_change_label(key, options)
    options[:html] ? content_tag(:strong, label(key)) : label(key)
  end

  def change_names(ids, key, options)
    names = names_for(ids, key)
    return names if names.blank? || !options[:html]

    content_tag(:i, h(names))
  end

  def set_change?(old_ids, new_ids)
    old_ids.any? && new_ids.any? && !(old_ids.one? && new_ids.one?)
  end

  def format_values(values, key)
    values.map { |value| names_for(ids_from(value), key).presence }
  end

  def names_for(ids, key)
    klass = class_from_field(key)
    return if klass.nil?

    ids.map { |id| name_or_placeholder(associated_object(klass, id)) }.join(", ")
  end

  def ids_from(value)
    value.to_s.split(",").map(&:to_i)
  end

  def name_or_placeholder(object)
    return I18n.t(:label_deleted_version) if object.nil?

    super
  end
end
