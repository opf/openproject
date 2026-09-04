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
  class PolymorphicAssociation < Attribute
    def render(key_with_gid, values, options = { html: true })
      key = key_with_gid.to_s.delete_suffix("_gid")
      label, old_value, value = format_details(key, values)

      if options[:html]
        label, old_value, value = *format_html_details(label, old_value, value)
      end

      render_ternary_detail_text(label, value, old_value, options)
    end

    private

    def format_details(key, values)
      label = label(key)

      old_value, value = *format_values(values)

      [label, old_value, value]
    end

    def format_values(values)
      values.map do |value|
        next if value.nil?

        record = associated_object(value)
        associated_object_name(record)
      end
    end

    def associated_object_name(object)
      object&.name
    end

    def associated_object(gid)
      global_id = GlobalID.parse(gid)
      return if global_id.nil?

      JournalFormatterCache.fetch(global_id.model_name, global_id.model_id) do # rubocop:disable Lint/UselessDefaultValueArgument
        locate(global_id)
      end
    end

    # The referenced record may have been destroyed after the journal was written,
    # e.g. a time entry logged on a work package that has since been deleted.
    # The detail is then rendered as if the value had been removed.
    def locate(global_id)
      GlobalID::Locator.locate(global_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
