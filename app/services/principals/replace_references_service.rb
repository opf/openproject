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

# Rewrites references to a principal from one principal to the other.
# No data is to be removed.
module Principals
  class ReplaceReferencesService
    class << self
      attr_reader :replacements, :foreign_keys

      def add_replacements(attributes_by_class_name)
        attributes_by_class_name.each do |class_name, attributes|
          Array(attributes).each { |attribute| add_replacement(class_name, attribute) }
        end
      end

      def add_replacement(class_name, attribute)
        @replacements ||= {}
        @replacements[class_name] ||= Set.new
        @replacements[class_name] << attribute

        @foreign_keys ||= Set.new
        @foreign_keys << attribute.to_s
      end
    end

    def call(from:, to:)
      rewrite_active_models(from, to)
      rewrite_custom_value(from, to)
      rewrite_default_journals(from, to)
      rewrite_customizable_journals(from, to)

      ServiceResult.success
    end

    private

    def rewrite_active_models(from, to)
      self.class.replacements.each do |class_name, attributes|
        klass = class_name.constantize
        attributes.each { |attribute| rewrite(klass, attribute, from, to) }
      end
    end

    def rewrite_custom_value(from, to)
      CustomValue
        .where(custom_field_id: CustomField.where(field_format: "user"))
        .where(value: from.id.to_s)
        .update_all(value: to.id.to_s)
    end

    def rewrite_default_journals(from, to)
      journal_classes.each do |klass|
        self.class.foreign_keys.each do |foreign_key|
          if klass.column_names.include? foreign_key
            rewrite(klass, foreign_key, from, to)
          end
        end
      end
    end

    def rewrite_customizable_journals(from, to)
      Journal::CustomizableJournal
        .joins(:custom_field)
        .where(custom_fields: { field_format: "user" })
        .where(value: from.id.to_s)
        .update_all(value: to.id.to_s)
    end

    def journal_classes
      [Journal] + Journal::BaseJournal.subclasses
    end

    def rewrite(klass, attribute, from, to)
      klass.where(attribute => from.id).update_all(attribute => to.id)
    end
  end
end
