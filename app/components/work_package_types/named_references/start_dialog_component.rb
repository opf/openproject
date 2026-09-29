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
    class StartDialogComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def self.form_id(model_class) = "#{model_class.reference_dom_key}-start-form"

      def initialize(model_class:, url:, candidates:, error: nil, type_record_id: nil)
        super()

        @model_class = model_class
        @url = url
        @candidates = candidates
        @error = error
        @type_record_id = type_record_id
      end

      private

      attr_reader :model_class, :url, :candidates, :error, :type_record_id

      def dialog_id = NameFormComponent.dialog_id(model_class)

      def form_id = self.class.form_id(model_class)

      def title = model_class.reference_t("start.title")

      def form_arguments
        { id: form_id, url:, method: :post, data: { turbo: true } }
      end
    end
  end
end
