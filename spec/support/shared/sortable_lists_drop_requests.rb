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

# The malformed coordinates every sortable-list drop endpoint rejects alike:
# SortableLists::DropRequestValidation screens list_type, list_id and prev_id
# before the endpoint resolves its own anchor. Endpoints keep the cases that
# are theirs -- which keys they accept as anchors, what a successful move
# persists -- in their own spec.
#
# Pass list_id_scoped: true for a list addressed by id among siblings and
# false for the one global list of its type, matching the controller's
# configure_drop_request.
#
# The including example group has to provide:
#
# * `valid_drop_params` - the params of a drop that would succeed
# * `dragged_id`        - the id the request addresses, for the self anchor
# * `send_drop(params)` - issues the drop request for `dragged_id`
# * `expect_unmoved`    - asserts the order the drop would have changed
RSpec.shared_examples "a sortable list drop endpoint" do |list_id_scoped:|
  scoped_list_id_case =
    if list_id_scoped
      { "a blank list_id" => -> { { list_id: "" } } }
    else
      { "a nonblank list_id" => -> { { list_id: dragged_id.to_s } } }
    end

  {
    "a wrong list_type" => -> { { list_type: "#{valid_drop_params[:list_type]}_lookalike" } },
    "an omitted list_type" => -> { { list_type: :omitted } },
    "an omitted prev_id" => -> { { prev_id: :omitted } },
    "a collection-valued prev_id" => -> { { prev_id: [valid_drop_params[:prev_id]] } },
    "an empty collection prev_id" => -> { { prev_id: [""] } },
    "a collection-valued list_id" => -> { { list_id: [valid_drop_params[:list_id]] } },
    "a self-referencing anchor" => -> { { prev_id: dragged_id.to_s } },
    "an unknown anchor" => -> { { prev_id: "999999" } },
    "a suffixed anchor id" => -> { { prev_id: "#{valid_drop_params[:prev_id]}junk" } }
  }.merge(scoped_list_id_case).each do |description, overrides|
    it "422s without mutation for #{description}", :aggregate_failures do
      params = valid_drop_params.merge(instance_exec(&overrides)).reject { |_, value| value == :omitted }

      send_drop(params)

      expect(response).to have_http_status(:unprocessable_entity)
      expect_unmoved
    end
  end
end
