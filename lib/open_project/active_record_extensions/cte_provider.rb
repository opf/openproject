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

module OpenProject
  module ActiveRecordExtensions
    # A Relation that renders as a single named CTE reference instead of a real
    # query. #build_arel returns a ProviderManager carrying the CTE name, bound
    # params and optional body; the Arel visitor emits the CTE.
    class CteProvider < ActiveRecord::Relation
      attr_accessor :provided_cte, :provided_cte_params

      # +model+ is the model the provider stands in for as a subquery. Although
      # build_arel emits the stored CTE, the model is still load-bearing: embedding
      # this relation via `where(id: provider)` makes ActiveRecord select the model's
      # primary key for the subquery, so it must be a real model (a primary-key-less
      # class such as ActiveRecord::Base raises).
      def initialize(model:, with:, params: {}, body: nil)
        @provided_cte = with
        @provided_cte_params = params
        @provided_cte_body = body

        super(model, table: with)
      end

      def build_arel(_aliases = nil)
        OpenProject::ActiveRecordExtensions::ProviderManager.new(@provided_cte, @provided_cte_params, @provided_cte_body)
      end
    end
  end
end
