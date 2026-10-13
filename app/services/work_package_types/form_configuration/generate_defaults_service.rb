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
  module FormConfiguration
    class GenerateDefaultsService
      def initialize(form, from: nil, custom_field_ids: nil)
        @form = form
        @source = from || form
        @custom_field_ids = custom_field_ids
      end

      def call
        return already_configured if form.form_groups.exists? || form.form_attributes.exists?

        generate
        ServiceResult.success(result: form)
      end

      private

      attr_reader :form, :source

      def generate
        ::FormConfiguration.transaction do
          source.default_attribute_groups(**{ custom_field_ids: @custom_field_ids }.compact)
                .each { |key, members| create_group(key, members) }
          EnsureAttributeMembershipService.new(form).call
        end
      end

      def create_group(default_key, members)
        group = form.form_groups.create!(kind: :attribute, default_key: default_key.to_s)

        members.each_with_index do |key, index|
          form.form_attributes.create!(group:, position: index + 1, **FormConfigurationAttribute.reference_for(key))
        end
      end

      def already_configured
        form.errors.add(:base, I18n.t("types.edit.form_configuration.defaults_not_generated.already_configured"))

        ServiceResult.failure(result: form, errors: form.errors)
      end
    end
  end
end
