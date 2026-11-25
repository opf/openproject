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

module SortableLists
  # Validates a drop endpoint's params against the frontend's sortable_lists
  # Stimulus controller: list_type and list_id per configure_drop_request
  # below, and a present, scalar prev_id.
  module DropRequestValidation
    extend ActiveSupport::Concern

    class_methods do
      # list_id_scoped: true for a list addressed by id among siblings
      # (e.g. custom fields within a section); false for the one global list
      # of its type (e.g. sections), which must receive a blank list_id.
      #
      # Pass exactly one of:
      # - list_type: a literal, for controllers whose list_type is the same
      #   for every instance (e.g. a model's SORTABLE_LIST_TYPE constant).
      # - list_type_method: a symbol naming an instance method, for
      #   controllers whose list_type is derived per-request (e.g. shared
      #   across several model subclasses).
      def configure_drop_request(list_id_scoped:, list_type: nil, list_type_method: nil)
        if list_type.nil? == list_type_method.nil?
          raise ArgumentError, "configure_drop_request requires exactly one of list_type or list_type_method"
        end

        define_method(:drop_list_type) do
          list_type_method ? send(list_type_method) : list_type
        end
        define_method(:drop_list_id_scoped?) { list_id_scoped }
      end
    end

    private

    def valid_drop_request?
      drop_params[:list_type] == drop_list_type &&
        (drop_list_id_scoped? ? drop_params[:list_id].present? : unscoped_list_id?) &&
        # key?, not present?: permit's scalar filter drops a missing or
        # array-valued prev_id alike, so a missing anchor can't be mistaken
        # for one to move to the top (that's a blank, present prev_id).
        drop_params.key?(:prev_id)
    end

    def unscoped_list_id?
      # Raw params, not drop_params: an array-valued list_id would read as
      # blank -- i.e. valid -- once permit's scalar filter drops it.
      params[:list_id].nil? || params[:list_id] == ""
    end

    def drop_params
      @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
    end
  end
end
