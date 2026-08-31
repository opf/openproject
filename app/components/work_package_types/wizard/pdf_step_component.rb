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
    # The PDF export wizard step: the reuse-mode banner over the export
    # configuration, shown read-only while the aspect is Linked. Mirrors the PDF
    # export tab and FormConfigurationStepComponent.
    class PdfStepComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:)
        super(variant)
      end

      def call
        render(WorkPackageTypes::ReloadableConfigurationFrameComponent.new(reload_url:)) do
          render(WorkPackageTypes::ReuseModeBannerComponent.new(
                   variant: model,
                   aspect: TypeVariant::PDF_EXPORT
                 )) +
            render(WorkPackageTypes::ExportConfigurationComponent.new(
                     model,
                     readonly: model.linked?(TypeVariant::PDF_EXPORT)
                   ))
        end
      end

      private

      def reload_url
        type_creation_wizard_path(**model.path_args, step: :pdf)
      end
    end
  end
end
