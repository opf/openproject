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

RSpec.shared_examples "an anchor-only enumeration move endpoint" do
  let(:drop_at_top_params) { { list_type:, list_id: "", prev_id: "" } }

  def drop_below_params(anchor)
    drop_at_top_params.merge(prev_id: anchor.id)
  end

  def move(record, params)
    put move_path(record), params:, as: :turbo_stream
  end

  it "moves the record to the top for a blank anchor" do
    move(third_record, drop_at_top_params)

    expect(response).to have_http_status(:ok)
    expect(ordered_names).to eq([third_record.name, first_record.name, second_record.name])
  end

  it "moves the record down, below a later anchor" do
    move(first_record, drop_below_params(third_record))

    expect(response).to have_http_status(:ok)
    expect(ordered_names).to eq([second_record.name, third_record.name, first_record.name])
  end

  it "moves the record up, below an earlier anchor" do
    move(third_record, drop_below_params(first_record))

    expect(response).to have_http_status(:ok)
    expect(ordered_names).to eq([first_record.name, third_record.name, second_record.name])
  end

  it "morphs the existing list boundary and reports success", :aggregate_failures do
    move(third_record, drop_at_top_params)

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body)
      .to have_css("turbo-stream[action='update'][method='morph'][target='#{morph_target}']", visible: :all)
    expect(response.body).to include(I18n.t(:enumeration_caption_order_changed))
    expect(response.body.index(%(target="#{morph_target}")))
      .to be < response.body.index(I18n.t(:enumeration_caption_order_changed))
  end

  {
    "a missing anchor" => -> { { list_type:, list_id: "" } },
    "an absent anchor ID" => lambda {
      { list_type:, list_id: "", prev_id: (first_record.class.maximum(:id) + 1_000).to_s }
    },
    "a self anchor" => -> { { list_type:, list_id: "", prev_id: first_record.id.to_s } },
    "a wrong list type with a valid anchor" => lambda {
      { list_type: "section", list_id: "", prev_id: second_record.id.to_s }
    },
    "a missing list type" => -> { { list_id: "", prev_id: "" } },
    "a nonblank list ID" => -> { { list_type:, list_id: second_record.id.to_s, prev_id: "" } },
    "an array anchor" => -> { { list_type:, list_id: "", prev_id: [""] } },
    "a hash anchor" => -> { { list_type:, list_id: "", prev_id: { id: "1" } } },
    "an array list ID" => -> { { list_type:, list_id: [""], prev_id: "" } },
    "a hash list ID" => -> { { list_type:, list_id: { id: "" }, prev_id: "" } },
    "a suffixed anchor ID" => -> { { list_type:, list_id: "", prev_id: "#{second_record.id}junk" } },
    "a legacy move_to request" => -> { { move_to: "lowest" } },
    "a retired position request" => -> { { position: 1 } }
  }.each do |description, params_builder|
    it "refuses #{description} without changing the order", :aggregate_failures do
      original_order = ordered_names

      move(first_record, instance_exec(&params_builder))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(ordered_names).to eq(original_order)
      expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
    end
  end

  {
    "an empty array list ID" => -> { { list_type:, list_id: [], prev_id: "" } },
    "an empty hash list ID" => -> { { list_type:, list_id: {}, prev_id: "" } },
    "a false list ID with a valid anchor" => -> { { list_type:, list_id: false, prev_id: second_record.id } },
    "a false anchor" => -> { { list_type:, list_id: "", prev_id: false } },
    "a fractional anchor ID" => -> { { list_type:, list_id: "", prev_id: second_record.id + 0.5 } }
  }.each do |description, params_builder|
    it "refuses #{description} in a JSON body without changing the order", :aggregate_failures do
      original_order = ordered_names

      put move_path(first_record),
          params: instance_exec(&params_builder).to_json,
          headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(ordered_names).to eq(original_order)
      expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
    end
  end
end

RSpec.shared_examples "an enumeration move endpoint refusing sibling-class anchors" do
  it "refuses an anchor of a sibling enumeration class without changing the order", :aggregate_failures do
    original_order = ordered_names

    put move_path(first_record), params: { list_type:, list_id: "", prev_id: sibling_record.id.to_s }, as: :turbo_stream

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_names).to eq(original_order)
  end
end
