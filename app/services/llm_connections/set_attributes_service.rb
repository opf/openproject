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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  class SetAttributesService < BaseServices::SetAttributes
    private

    def set_attributes(params)
      super

      model.base_url = normalized_base_url if model.base_url.present?
      set_singleton_defaults
    end

    # +name+ and +type+ identify the record but are never user-editable, so they
    # are set as system changes: the contract's readonly check only looks at
    # attributes the user changed.
    def set_singleton_defaults
      model.change_by_system do
        model.name ||= LlmConnection::SINGLETON_NAME
        model.type ||= LlmConnection.name
      end
    end

    # Only trailing whitespace and slashes are removed. The /v1 segment is
    # deliberately not added or stripped: silently rewriting an administrator's
    # URL makes the eventual failure harder to diagnose, so a wrong shape is
    # reported by the probe instead.
    def normalized_base_url
      model.base_url.strip.chomp("/")
    end
  end
end
