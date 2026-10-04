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
  module NamedReferences
    class PageHeaderComponent < ApplicationComponent
      include Translatable
      include OpPrimer::ComponentHelpers

      def initialize(record:, model_class:)
        super()

        @record = record
        @model_class = model_class
      end

      private

      attr_reader :record, :model_class

      def breadcrumbs
        [{ href: helpers.admin_index_path, text: t("label_administration") },
         { href: helpers.types_path, text: t(:label_type_plural) },
         { href: helpers.polymorphic_path(model_class), text: model_class.model_name.human(count: 2) },
         record.name]
      end

      def mark_default? = model_class.defaultable? && !record.marked_default?

      def test_selector(part) = "#{dom_class(model_class)}-#{part}"
    end
  end
end
