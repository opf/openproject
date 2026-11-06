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

require "spec_helper"

RSpec.describe "Type ordering", :skip_csrf,
               type: :rails_request,
               with_settings: { per_page_options: "2,100" } do
  current_user { create(:admin) }

  let!(:types) { %w[A B C D E].map { |name| create(:type, name:) } }
  let(:drag_params) { { list_type: Type.model_name.param_key, list_id: "", prev_id: "" } }

  def type_named(name) = Type.find_by!(name:)

  def expect_order(*names)
    expect(Type.order(:position).pluck(:name)).to eq(names)
  end

  def turbo_fragment
    Capybara.string(
      Nokogiri::HTML(response.parsed_body).css("turbo-stream[action=update] template").map(&:inner_html).join
    )
  end

  def drop(name, request_params = drag_params, page: 2, **context)
    put move_type_path(type_named(name), page:, per_page: 2, **context),
        params: request_params,
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def expect_refused(*names)
    aggregate_failures do
      expect(response).to have_http_status(:unprocessable_entity)
      expect_order(*names)
    end
  end

  [nil, ""].each do |anchor|
    it "moves to page two's beginning for #{anchor.inspect}", :aggregate_failures do
      drop("D", drag_params.merge(prev_id: anchor), expand: type_named("D").id)

      expect(response).to have_http_status(:ok)
      expect_order("A", "B", "D", "C", "E")
      expect(response).to have_turbo_stream(action: "update", method: "morph",
                                            target: WorkPackageTypes::Types::GroupedListComponent.wrapper_key)
      expand = type_named("D").id
      expect(turbo_fragment).to have_link("1", href: types_path(page: 1, per_page: 2, expand:))
      expect(turbo_fragment).to have_link("3", href: types_path(page: 3, per_page: 2, expand:))
      expect(turbo_fragment).to have_no_css("[href*='/move']")
    end

    it "moves to the global beginning on page one for #{anchor.inspect}" do
      drop("B", drag_params.merge(prev_id: anchor), page: 1)

      expect(response).to have_http_status(:ok)
      expect_order("B", "A", "C", "D", "E")
    end
  end

  it "moves below an explicit predecessor on page two" do
    drop("C", drag_params.merge(prev_id: type_named("D").id))

    expect(response).to have_http_status(:ok)
    expect_order("A", "B", "D", "C", "E")
  end

  [false, true, 1.5, 0, -1, "01", "1junk", " ", [], {}].each do |anchor|
    it "rejects malformed anchor #{anchor.inspect}" do
      drop("D", drag_params.merge(prev_id: anchor))

      expect_refused("A", "B", "C", "D", "E")
    end
  end

  [false, true, "1", [], {}].each do |list_id|
    it "rejects destination #{list_id.inspect}" do
      drop("D", drag_params.merge(list_id:))

      expect_refused("A", "B", "C", "D", "E")
    end
  end

  {
    "missing anchor" => { list_type: "type" },
    "missing type" => { prev_id: "" },
    "wrong type" => { list_type: "status", prev_id: "" },
    "unknown anchor" => { list_type: "type", prev_id: "99999999" },
    "absolute position" => { position: 1 }
  }.each do |description, request_params|
    it "rejects #{description}" do
      drop("D", request_params)

      expect_refused("A", "B", "C", "D", "E")
    end
  end

  it "rejects a self anchor" do
    drop("D", drag_params.merge(prev_id: type_named("D").id))

    expect_refused("A", "B", "C", "D", "E")
  end

  it "rejects a page boundary that resolves to the moved type" do
    drop("B")

    expect_refused("A", "B", "C", "D", "E")
  end

  it "rejects an empty page" do
    type_named("E").destroy!
    drop("C", page: 3)

    expect_refused("A", "B", "C", "D")
  end

  it "ignores a non-scalar expansion parameter when dropping" do
    drop("D", expand: ["1"])

    expect(response).to have_http_status(:ok)
    expect_order("A", "B", "D", "C", "E")
  end

  it "preserves variant membership and alphabetical order" do
    zeta = create(:type_variant, type: type_named("D"), variant_name: "Zeta")
    alpha = create(:type_variant, type: type_named("D"), variant_name: "Alpha")
    drop("D")

    expect(response).to have_http_status(:ok)
    expect(type_named("D").variants.non_default_variants.in_display_order).to eq([alpha, zeta])
    expect([alpha.reload.type_id, zeta.reload.type_id]).to eq([type_named("D").id] * 2)
  end

  {
    highest: ["D", %w[D A B C E]],
    higher: ["C", %w[A C B D E]],
    lower: ["D", %w[A B C E D]],
    lowest: ["C", %w[A B D E C]]
  }.each do |direction, (name, names)|
    it "moves #{direction} globally and refreshes the current page", :aggregate_failures do
      put move_type_path(type_named(name), page: 2, per_page: 2),
          params: { move_to: direction }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect_order(*names)
      expect(response.body).to include(I18n.t(:notice_successful_update))
      expect(turbo_fragment.all(:heading).map { it.text.squish }).to eq(names[2, 2])
      expect(turbo_fragment).to have_link("1", href: types_path(page: 1, per_page: 2))
      expect(turbo_fragment).to have_link("3", href: types_path(page: 3, per_page: 2))
    end
  end

  [nil, "sideways", false, [], {}].each do |direction|
    it "rejects invalid direction #{direction.inspect}" do
      put move_type_path(type_named("D"), page: 2, per_page: 2),
          params: { move_to: direction }, as: :json,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect_refused("A", "B", "C", "D", "E")
    end
  end

  it "keeps page context in the lazy menu forms", :aggregate_failures do
    get menu_type_path(type_named("C"), page: 2, per_page: 2, expand: type_named("C").id)

    expect(response).to have_http_status(:ok)
    form_action = move_type_path(type_named("C"), page: 2, per_page: 2, expand: type_named("C").id)
    expect(response.body).to have_element(:form, action: form_action, count: 4)
    expect(response.body).to have_field("_method", type: :hidden, with: "put", count: 4)
    expect(response.body).to have_field("move_to", type: :hidden, with: "higher")
  end

  it "responds with not found when dropping an unknown type", :aggregate_failures do
    put move_type_path(0, page: 2, per_page: 2),
        params: drag_params,
        as: :json,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:not_found)
    expect_order("A", "B", "C", "D", "E")
  end

  it "responds with not found when moving an unknown type by direction", :aggregate_failures do
    put move_type_path(0, page: 2, per_page: 2), params: { move_to: "highest" }, as: :turbo_stream

    expect(response).to have_http_status(:not_found)
    expect_order("A", "B", "C", "D", "E")
  end

  context "without admin permission" do
    current_user { create(:user) }

    it "rejects dragging" do
      drop("D")

      expect(response).to have_http_status(:forbidden)
      expect_order("A", "B", "C", "D", "E")
    end

    it "rejects menu moves" do
      put move_type_path(type_named("D")), params: { move_to: "highest" }, as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect_order("A", "B", "C", "D", "E")
    end
  end
end
