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

module Mailer
  LABEL_SCHEME_COLORS = {
    default: "rgb(208, 215, 222)",
    primary: "rgb(110, 119, 129)",
    secondary: "rgb(208, 215, 222)",
    accent: "rgb(9, 105, 218)",
    success: "rgb(31, 136, 61)",
    attention: "rgb(154, 103, 0)",
    danger: "rgb(207, 34, 46)",
    severe: "rgb(188, 76, 0)",
    done: "rgb(130, 80, 223)",
    sponsor: "rgb(191, 57, 137)"
  }.freeze

  class LabelComponent < ViewComponent::Base
    include MailLayoutHelper

    def initialize(scheme:, text:)
      super

      @color = LABEL_SCHEME_COLORS[scheme]
      @text = text
    end
  end
end
