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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  # Admin URLs for a custom field, derived from its type. Every custom field is
  # administered at admin_settings_<type>_custom_field[...], so the helper name is
  # built from the type rather than spelled out per type.
  module AdminRoutes
    def index_path(subject, **params)
      op_routes.public_send(:"admin_settings_#{cf_plural(subject)}_path", **params)
    end

    def new_path(subject, field_format: nil)
      op_routes.public_send(:"new_admin_settings_#{cf_singular(subject)}_path", field_format:)
    end

    def edit_path(custom_field, *, **)
      # Project custom fields render their edit form through the member 'show' route.
      prefix = custom_field.is_a?(ProjectCustomField) ? "" : "edit_"
      op_routes.public_send(:"#{prefix}admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    def member_path(custom_field)
      op_routes.public_send(:"admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    def list_item_path(custom_field, *, **)
      op_routes.public_send(:"list_items_admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    def delete_option_path(custom_field, custom_option)
      op_routes.public_send(:"delete_option_of_admin_settings_#{cf_singular(custom_field)}_path",
                            custom_field.id || 0, custom_option.id || 0)
    end

    def reorder_alphabetical_path(custom_field)
      op_routes.public_send(:"reorder_alphabetical_admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    def attribute_help_text_path(custom_field)
      op_routes.public_send(:"attribute_help_text_admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    def update_attribute_help_text_path(custom_field)
      op_routes.public_send(:"update_attribute_help_text_admin_settings_#{cf_singular(custom_field)}_path", custom_field)
    end

    private

    def cf_singular(subject)
      cf_class(subject).name.underscore
    end

    def cf_plural(subject)
      cf_singular(subject).pluralize
    end

    def cf_class(subject)
      case subject
      when Class then subject
      when String then subject.constantize
      else subject.class
      end
    end

    def op_routes = Rails.application.routes.url_helpers
  end
end
