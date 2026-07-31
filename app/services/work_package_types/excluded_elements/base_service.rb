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
    # Shared scaffolding for narrowing what a type inherits for one aspect. Subclasses only
    # implement #updated_elements.
    #
    # Exclusions are a property of a *link*, not of a type: they describe what this type drops
    # from what it inherits. A type that owns the aspect has nothing to exclude — it edits its
    # own configuration directly — so the services fail rather than silently doing nothing.
    #
    # Writes target the type's own link only. A type can never narrow an ancestor's link; that
    # ancestor's exclusions reach it through the chain instead.
    class BaseService < ::BaseServices::BaseCallable
      def initialize(user:, type:)
        super()
        @user = user
        @type = type
      end

      def perform(*)
        aspect = params[:aspect].to_s
        return unknown_aspect_result(aspect) unless Type::ConfigurationLink::ASPECTS.include?(aspect)

        link = type.configuration_links.find_by(aspect:)
        return not_linked_result unless link

        narrow(link)
      end

      protected

      attr_reader :type, :user

      # The element list to persist, given the link's current list and the requested elements.
      def updated_elements(_current, _requested)
        raise SubclassResponsibilityError
      end

      private

      def narrow(link)
        link.update!(excluded_elements: updated_elements(link.excluded_elements, elements_param))

        ServiceResult.success(result: type)
      rescue ActiveRecord::RecordInvalid
        ServiceResult.failure(result: type, errors: link.errors)
      end

      # Element keys are aspect-specific strings (see Type::ConfigurationLinkable), so they are
      # only normalised here — an unknown key is inert rather than invalid, and the aspect's
      # reader is what interprets them.
      def elements_param
        Array(params[:elements]).map { |element| element.to_s.strip }.compact_blank
      end

      def not_linked_result
        type.errors.add(:base, I18n.t("types.edit.reuse_mode.exclusions.not_linked"))

        ServiceResult.failure(result: type, errors: type.errors)
      end

      def unknown_aspect_result(aspect)
        type.errors.add(:base, I18n.t("types.edit.reuse_mode.exclusions.unknown_aspect", aspect:))

        ServiceResult.failure(result: type, errors: type.errors)
      end
    end
  end
end
