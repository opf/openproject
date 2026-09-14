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
  module CopyConfiguration
    # Shared scaffolding for the per-aspect copy services: the source guard and a
    # template `call` that adopts the source's resolved configuration onto the
    # variant. Aspects whose copy is a straight column adoption only implement
    # #aspect and #copy_from; aspects with a richer copy (form configuration)
    # override #call.
    class BaseService
      def initialize(variant:, user:)
        @variant = variant
        @user = user
      end

      def call(source:)
        return invalid_source_result unless valid_source?(source)

        copy_from(source.effective_source_for(aspect))

        ServiceResult.success(result: variant)
      rescue ActiveRecord::RecordInvalid
        ServiceResult.failure(result: variant, errors: variant.errors)
      end

      private

      attr_reader :variant, :user

      def aspect
        raise SubclassResponsibilityError
      end

      # A Linked source presents its inherited configuration, so #call resolves
      # the owning variant first and hands it here to adopt.
      def copy_from(_source)
        raise SubclassResponsibilityError
      end

      def valid_source?(source)
        source.present? && source != variant
      end

      def invalid_source_result
        variant.errors.add(:base, I18n.t("types.edit.reuse_mode.copy.invalid_source"))

        ServiceResult.failure(result: variant, errors: variant.errors)
      end
    end
  end
end
