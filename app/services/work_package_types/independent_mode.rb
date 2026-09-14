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
  # The starting points offered when switching a configuration aspect to
  # Independent, and which of them each aspect offers. COPY starts from the
  # currently linked source; DEFAULT starts from a fresh type (the
  # administrator's defaults for new types); EMPTY starts from a blank
  # configuration. Each aspect only lists the modes meaningful for it: form
  # configuration cannot represent an empty form, and PDF export stores its
  # templates as a disabled-list, so a blank configuration would present as
  # every template enabled rather than as an empty one.
  module IndependentMode
    COPY = "copy"
    DEFAULT = "default"
    EMPTY = "empty"

    AVAILABLE = {
      TypeVariant::FORM_CONFIGURATION => [COPY, DEFAULT],
      TypeVariant::DEFAULTS => [COPY, EMPTY],
      TypeVariant::PDF_EXPORT => [COPY, DEFAULT],
      TypeVariant::WORKFLOWS => [COPY, EMPTY],
      TypeVariant::PROJECT_ATTRIBUTES => [COPY, EMPTY]
    }.freeze

    module_function

    def available_for(aspect)
      AVAILABLE.fetch(aspect.to_s, [])
    end

    def available?(aspect, mode)
      available_for(aspect).include?(mode.to_s)
    end
  end
end
