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
    class NameFormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def self.dialog_id(model_class) = "#{ActionView::RecordIdentifier.dom_class(model_class)}-dialog"

      def self.form_id(model_class) = "#{ActionView::RecordIdentifier.dom_class(model_class)}-form"

      def initialize(record:, model_class:, copy_from_id: nil, ask_copy_source: true, url: nil)
        super()

        @record = record
        @model_class = model_class
        @copy_from_id = copy_from_id
        @ask_copy_source = ask_copy_source
        @url = url
      end

      def form_arguments
        {
          id: self.class.form_id(model_class),
          model: record,
          scope: record.model_name.param_key,
          url: form_url,
          method: record.persisted? ? :patch : :post,
          data: { turbo: true }
        }
      end

      private

      attr_reader :record, :model_class, :copy_from_id, :ask_copy_source, :url

      def form_url
        return url if url.present?
        return url_helpers.polymorphic_path(record) if record.persisted?

        url_helpers.polymorphic_path(model_class)
      end

      def error_message
        return if record.errors.empty?

        record.errors.full_messages.to_sentence
      end
    end
  end
end
