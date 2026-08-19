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

module WorkPackageTypes
  module Patterns
    AttributeToken = Data.define(:key, :label_fn, :resolve_fn, :formatter) do
      def label_with_context
        attribute_context = I18n.t("types.edit.subject_configuration.token.context.#{context}")
        I18n.t("types.edit.subject_configuration.token.label_with_context", attribute_context:, attribute_label: label)
      end

      def label(*)
        label_fn.call(*)
      end

      def call(*)
        value = resolve_fn.call(*)
        formatter.call(value)
      end

      def context
        case key.to_s
        when /^project_/
          :project
        when /^parent_/
          :parent
        else
          :work_package
        end
      end

      # --- Equality overrides ---
      # We want to make sure that two tokens are considered equal if they represent the attribute. This is regardless
      # of identity of the methods used to resolve their labels etc.

      def ==(other)
        eql?(other)
      end

      def eql?(other)
        self.class == other.class && key == other.key
      end

      def hash
        [self.class, key].hash
      end
      # --- END Equality overrides ---
    end
  end
end
