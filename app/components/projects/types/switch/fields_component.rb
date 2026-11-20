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

module Projects
  module Types
    module Switch
      # Everything the switch asks for and reports, with no container of its
      # own: the dialog wraps this in Dialog::Body, and a settings page could
      # wrap the same component in page chrome instead.
      class FieldsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers

        # Nil when there is nothing to report: the variant in use is selected, or the projects start
        # from different variants.
        def initialize(form:, targets:, selected:, validation_message: nil, impact: nil)
          super()

          @form = form
          @targets = targets
          @selected = selected
          @validation_message = validation_message
          @impact = impact
        end
      end
    end
  end
end
