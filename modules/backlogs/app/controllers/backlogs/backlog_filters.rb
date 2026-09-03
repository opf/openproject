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
        bucket_ids: parse_ids(params[:bucket_ids]) { |id| id == "inbox" ? "inbox" : id.to_i.nonzero? },
        sprint_ids: parse_ids(params[:sprint_ids]) { |id| id.to_i.nonzero? },
        show_all: ActiveRecord::Type::Boolean.new.cast(params[:all]) || false
      )
    end

    # Coerces a raw filter param into a deduplicated list of ids, or nil when
    # empty. Accepts both the compact comma-delimited form ("1,2,inbox") and a
    # plain array (["1", "2"]). Tampered or nested structures (e.g. the URL
    # +?bucket_ids[0]=5+, which arrives as a Hash/ActionController::Parameters)
    # are ignored rather than raising.
    def self.parse_ids(raw, &)
      tokenize(raw).filter_map(&).uniq.presence
    end

    def self.tokenize(raw)
      case raw
      when String then raw.split(",")
      when Array then raw
      else []
      end.filter_map { |value| value.to_s.strip.presence }
    end
    private_class_method :tokenize

    def show_inbox?
      bucket_ids.nil? || bucket_ids.include?("inbox")
    end

    # Serializes back to query params, joining id lists into the compact
    # comma-delimited form so generated URLs stay bookmarkable
    # (+?bucket_ids=1,2+ rather than +?bucket_ids[]=1&bucket_ids[]=2+).
    def to_h
      result = show_all? ? { all: true } : {}
      result[:bucket_ids] = bucket_ids.join(",") if bucket_ids
      result[:sprint_ids] = sprint_ids.join(",") if sprint_ids
      result
    end

    alias to_hash to_h
    alias show_all? show_all
  end
end
