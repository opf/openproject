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
      label, old_value, value = format_details(key, values, cache: options[:cache])

      if options[:html]
        label, old_value, value = *format_html_details(label, old_value, value)
      end

      render_ternary_detail_text(label, value, old_value, options)
    end

    private

    def format_details(key, values, cache:)
      label = label(key)

      old_value, value = *format_values(values, key, cache:)

      [label, old_value, value]
    end

    def format_values(values, key, cache:)
      klass = class_from_field(key)

      values.map do |value|
        if klass && value
          record = associated_object(klass, value.to_i, cache:)
          if record
            if record.respond_to? :name
              record.name
            else
              record.subject
            end
          end
        end
      end
    end

    def associated_object(klass, id, cache:)
      if cache
        cache.fetch(klass, id) do
          klass.find_by(id:)
        end
      else
        klass.find_by(id:)
      end
    end

    def class_from_field(field)
      association = @journal.journable.class.reflect_on_association(field)

      association&.klass
    end
  end
end
