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

module StepWizard
  class PageLayoutComponent < ViewComponent::Base
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    renders_one :page_header, Primer::Content

    renders_one :footer, Primer::Content

    renders_one :wizard_content, lambda { |**content_arguments|
      @content_arguments = content_arguments
      Primer::Content.new
    }

    def initialize(**container_arguments)
      super()

      @container_arguments = container_arguments
      @container_arguments[:class] = class_names(
        @container_arguments[:class],
        "step-wizard-page"
      )
    end
  end
end
