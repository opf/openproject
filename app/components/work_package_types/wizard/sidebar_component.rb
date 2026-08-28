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
  module Wizard
    class SidebarComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(type:, current_step:, variant: nil, back_url: nil)
        super(type)

        @current_step = current_step
        @variant = variant
        @back_url = back_url
      end

      LEADING_ICONS = {
        details: :info,
        defaults: :"file-diff",
        form_configuration: :"list-unordered",
        project_attributes: :project,
        workflows: :"git-branch",
        projects: :table,
        pdf: :file
      }.freeze

      ASPECTS = {
        defaults: TypeVariant::DEFAULTS,
        form_configuration: TypeVariant::FORM_CONFIGURATION,
        project_attributes: TypeVariant::PROJECT_ATTRIBUTES,
        workflows: TypeVariant::WORKFLOWS,
        pdf: TypeVariant::PDF_EXPORT
      }.freeze

      private

      attr_reader :current_step, :variant, :back_url

      def type = model

      def steps = Steps.available_for(variant)

      def leading_icon(step) = LEADING_ICONS.fetch(step)

      def title(step) = Steps.title(step)

      def current?(step) = step == current_step

      def completed?(step)
        record_persisted? && Steps.index(step) < Steps.index(current_step)
      end

      def linked?(step)
        aspect = ASPECTS[step]
        aspect.present? && variant&.linked?(aspect)
      end

      def href_for(step)
        type_creation_wizard_path(**variant_path_args, step:, back_url:) if record_persisted?
      end

      def variant_path_args = variant&.path_args || { type_id: type.id }

      def record_persisted? = variant ? variant.persisted? : type.persisted?
    end
  end
end
