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

module FullCalendar
  class Event
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :string
    attribute :group_id, :string
    attribute :all_day, :boolean, default: false
    attribute :starts_at, :datetime
    attribute :ends_at, :datetime
    attribute :title, :string
    attribute :url, :string
    attribute :class_names, array: true, default: []

    # override in subclasses to add more fields to the JSON
    def additional_attributes
      {}
    end

    def as_json
      {
        "id" => id,
        "groupId" => group_id,
        "allDay" => all_day,
        "start" => starts_at,
        "end" => ends_at,
        "title" => title,
        "url" => url,
        "classNames" => class_names
      }.merge(additional_attributes).compact.as_json
    end

    def to_json(*)
      as_json.to_json(*)
    end
  end
end
