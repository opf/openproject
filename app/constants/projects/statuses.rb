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
  module Statuses
    Status = Data.define(:code, :color, :icon) do
      def id = code&.to_s || :none
      def value = code&.to_s
    end

    NOT_SET = Status.new(code: nil, color: Color.new(hexcode: "#24292F"), icon: "issue-draft")
    ON_TRACK = Status.new(code: :on_track, color: Color.new(hexcode: "#1F883D"), icon: "issue-opened")
    AT_RISK = Status.new(code: :at_risk, color: Color.new(hexcode: "#BC4C00"), icon: "alert")
    OFF_TRACK = Status.new(code: :off_track, color: Color.new(hexcode: "#CF222E"), icon: "stop")
    NOT_STARTED = Status.new(code: :not_started, color: Color.new(hexcode: "#0969DA"), icon: "circle")
    FINISHED = Status.new(code: :finished, color: Color.new(hexcode: "#8250DF"), icon: "issue-closed")
    DISCONTINUED = Status.new(code: :discontinued, color: Color.new(hexcode: "#9A6700"), icon: "no-entry")

    VALID = [
      ON_TRACK,
      AT_RISK,
      OFF_TRACK,
      NOT_STARTED,
      FINISHED,
      DISCONTINUED
    ].freeze

    AVAILABLE = [NOT_SET, *VALID].freeze
  end
end
