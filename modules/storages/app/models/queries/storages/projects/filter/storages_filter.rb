# frozen_string_literal: true

# -- copyright
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
# ++
#

# This filter is used to find projects (including archived projects) that use one
# of the given storages ids.
module Queries::Storages::Projects::Filter
  class StoragesFilter < ::Queries::Projects::Filters::Base
    def self.key
      :storages
    end

    def type
      :list
    end

    def allowed_values
      @allowed_values ||= Storages::Storage
                            .pluck(:name, :id)
    end

    def available?
      User.current.admin?
    end

    def apply_to(_query_scope)
      case operator
      when "="
        super.activated_in_storage(values)
      when "!"
        super.not_activated_in_storage(values)
      else
        raise "unsupported operator"
      end
    end

    def where
      nil
    end
  end
end
