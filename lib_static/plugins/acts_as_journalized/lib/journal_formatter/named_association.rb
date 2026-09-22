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

module JournalFormatter
  class NamedAssociation < Attribute
    def render(key_with_id, values, options = { html: true })
      key = key_with_id.to_s.delete_suffix("_id")
      label, old_value, value = format_details(key, values)

      if options[:html]
        label, old_value, value = *format_html_details(label, old_value, value)
      end

      render_ternary_detail_text(label, value, old_value, options)
    end

    private

    def format_details(key, values)
      label = label(key)

      old_value, value = *format_values(values, key)

      [label, old_value, value]
    end

    def format_values(values, key)
      klass = class_from_field(key)

      values.map do |value|
        next unless klass && value

        name_or_placeholder(associated_object(klass, value.to_i))
      end
    end

    def name_or_placeholder(object)
      return associated_object_name(object) if object.nil? || reachable?(object)

      I18n.t("journals.non_visible.#{object.model_name.i18n_key}",
             default: I18n.t("journals.non_visible.default"))
    end

    # A journal outlives the reader's access to what it references: a work package
    # moved between projects keeps journal entries naming the parent, version,
    # category and budget it had in a project the reader cannot open.
    #
    # The reader is folded into the cache key by default, so a verdict left behind in
    # a thread that outlives a single request cannot be read back for somebody else.
    #
    # :journal_reachable is used as the "klass" part of the key so this verdict cache
    # never collides with the raw-record cache entries #associated_object stores under
    # the object's actual class.
    #
    # Overridden by PublicNamedAssociation to skip the check for fields that name
    # people the journable already names elsewhere (assignee, responsible, author).
    def reachable?(object)
      JournalFormatterCache.fetch(:journal_reachable, [object.class, object.id]) do # rubocop:disable Lint/UselessDefaultValueArgument
        reader_may_see?(object)
      end
    end

    def reader_may_see?(object)
      return object.visible? if object.respond_to?(:visible?)

      project = object.try(:project)
      project.nil? || project.visible?
    end

    def associated_object_name(object)
      object&.name
    end

    def associated_object(klass, id)
      JournalFormatterCache.fetch(klass, id) do # rubocop:disable Lint/UselessDefaultValueArgument
        klass.find_by(id:)
      end
    end

    def class_from_field(field)
      association = @journal.journable.class.reflect_on_association(field)

      association&.klass || field.to_s.camelize.safe_constantize
    end
  end
end
