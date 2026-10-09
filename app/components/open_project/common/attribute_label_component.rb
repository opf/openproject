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

module OpenProject
  module Common
    class AttributeLabelComponent < ApplicationComponent
      include AttributeHelpTextsHelper

      def initialize(
        attribute:,
        model:,
        tag: :span,
        current_user: User.current,
        required: false,
        **system_arguments
      )
        super()

        @tag = tag
        @system_arguments = system_arguments
        @system_arguments[:tag] = @tag
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "op-attribute-label"
        )

        @required = required
        @help_text = help_text_for(model, attribute, current_user:)
      end
    end
  end
end
