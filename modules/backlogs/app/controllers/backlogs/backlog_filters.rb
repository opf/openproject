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

module Backlogs
  BacklogFilters = Data.define(:bucket_ids, :sprint_ids, :show_all) do
    def self.from_params(params)
      new(
        bucket_ids: Array(params[:bucket_ids]).filter_map do |id|
                      id == "inbox" ? "inbox" : id.to_i.nonzero?
                    end.presence,
        sprint_ids: Array(params[:sprint_ids]).filter_map { |id| id.to_i.nonzero? }.presence,
        show_all: ActiveRecord::Type::Boolean.new.cast(params[:all]) || false
      )
    end

    def show_inbox?
      bucket_ids.nil? || bucket_ids.include?("inbox")
    end

    def to_h
      result = show_all? ? { all: true } : {}
      result[:bucket_ids] = bucket_ids if bucket_ids
      result[:sprint_ids] = sprint_ids if sprint_ids
      result
    end

    alias to_hash to_h
    alias show_all? show_all
  end
end
