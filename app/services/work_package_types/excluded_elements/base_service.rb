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
  module ExcludedElements
    # Shared scaffolding for narrowing what a variant inherits for one aspect. Subclasses only
    # implement #updated_elements.
    #
    # Exclusions describe what this variant drops from what it inherits, so they only mean
    # something while the aspect is linked. A variant that owns the aspect has nothing to
    # exclude — it edits its own configuration directly — so the services fail rather than
    # silently doing nothing.
    #
    # Writes target this variant's own exclusions only. A variant can never narrow an
    # ancestor's; that ancestor's exclusions reach it through the chain instead.
    class BaseService < ::BaseServices::BaseCallable
      def initialize(user:, variant:)
        super()
        @user = user
        @variant = variant
      end

      def perform(*)
        aspect = params[:aspect].to_s
        return unknown_aspect_result(aspect) unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)
        return not_linked_result unless variant.linked?(aspect)

        narrow(aspect)
      end

      protected

      attr_reader :variant, :user

      def updated_elements(_current, _requested)
        raise SubclassResponsibilityError
      end

      private

      # The exclusions are an array column, so the read-modify-write needs a lock. The lock is
      # taken on the variant rather than per aspect, which serialises concurrent edits to
      # unrelated aspects of the same variant.
      def narrow(aspect)
        column = :"#{TypeVariant.validated_excludable_aspect(aspect)}_excluded_elements"

        OpenProject::Mutex.with_advisory_lock_transaction(variant, "excluded_elements") do
          variant.reload
          variant.update!(column => next_elements(column))
        end

        ServiceResult.success(result: variant)
      rescue ActiveRecord::RecordInvalid
        ServiceResult.failure(result: variant, errors: variant.errors)
      end

      def next_elements(column)
        updated_elements(variant.public_send(column), elements_param)
      end

      # Element keys are aspect-specific strings (see TypeVariant::ConfigurationLinkable), so
      # they are only normalised here — an unknown key is inert rather than invalid, and the
      # aspect's reader is what interprets them.
      def elements_param
        Array(params[:elements]).map { |element| element.to_s.strip }.compact_blank
      end

      def not_linked_result
        variant.errors.add(:base, I18n.t("types.edit.reuse_mode.exclusions.not_linked"))

        ServiceResult.failure(result: variant, errors: variant.errors)
      end

      def unknown_aspect_result(aspect)
        variant.errors.add(:base, I18n.t("types.edit.reuse_mode.exclusions.unknown_aspect", aspect:))

        ServiceResult.failure(result: variant, errors: variant.errors)
      end
    end
  end
end
