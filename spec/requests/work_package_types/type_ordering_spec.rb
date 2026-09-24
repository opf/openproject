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

require "spec_helper"

RSpec.describe "Type ordering", :skip_csrf, type: :rails_request,
                                            with_settings: { per_page_options: "2,100" } do
  current_user { create(:admin) }

  let!(:types) { %w[A B C D E].map { |name| create(:type, name:) } }
  let(:drag_params) { { list_type: Type.model_name.param_key, list_id: "", prev_id: "" } }

  def expect_order(*names)
    expect(Type.order(:position).pluck(:name)).to eq(names)
  end

  def drop(type, request_params = drag_params, page: 2)
    put drop_type_path(type, page:, per_page: 2), params: request_params,
                                                  as: :json, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  [nil, ""].each do |anchor|
    it "moves to page two's beginning for #{anchor.inspect}" do
      drop(types[3], drag_params.merge(prev_id: anchor))

      expect(response).to have_http_status(:ok)
      expect_order("A", "B", "D", "C", "E")
      expect(response.body).to have_css('turbo-stream[action="update"][method="morph"]' \
                                        '[target="work-package-types-types-grouped-list-component"]')
    end

    it "moves to the global beginning on page one for #{anchor.inspect}" do
      drop(types[1], drag_params.merge(prev_id: anchor), page: 1)

      expect(response).to have_http_status(:ok)
      expect_order("B", "A", "C", "D", "E")
    end
  end

  it "moves below an explicit predecessor on page two" do
    drop(types[2], drag_params.merge(prev_id: types[3].id))

    expect(response).to have_http_status(:ok)
    expect_order("A", "B", "D", "C", "E")
  end

  [false, true, 1.5, 0, -1, "01", "1junk", " ", [], {}].each do |anchor|
    it "rejects malformed anchor #{anchor.inspect}" do
      drop(types[3], drag_params.merge(prev_id: anchor))

      expect(response).to have_http_status(:unprocessable_entity)
      expect_order("A", "B", "C", "D", "E")
    end
  end

  [false, true, "1", [], {}].each do |list_id|
    it "rejects destination #{list_id.inspect}" do
      drop(types[3], drag_params.merge(list_id:))

      expect(response).to have_http_status(:unprocessable_entity)
      expect_order("A", "B", "C", "D", "E")
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
      drop(types[3], request_params)

      expect(response).to have_http_status(:unprocessable_entity)
      expect_order("A", "B", "C", "D", "E")
    end
  end

  it "rejects a self anchor" do
    drop(types[3], drag_params.merge(prev_id: types[3].id))

    expect(response).to have_http_status(:unprocessable_entity)
    expect_order("A", "B", "C", "D", "E")
  end

  it "rejects a page boundary that resolves to the moved type" do
    drop(types[1])

    expect(response).to have_http_status(:unprocessable_entity)
    expect_order("A", "B", "C", "D", "E")
  end

  it "rejects an empty page" do
    types.last.destroy!
    drop(types[2], page: 3)

    expect(response).to have_http_status(:unprocessable_entity)
    expect_order("A", "B", "C", "D")
  end

  {
    highest: [3, %w[D A B C E]],
    higher: [2, %w[A C B D E]],
    lower: [3, %w[A B C E D]],
    lowest: [2, %w[A B D E C]]
  }.each do |direction, (index, names)|
    it "moves #{direction} globally and refreshes the current page" do
      post move_types_path(types[index], page: 2, per_page: 2),
           params: { type: { move_to: direction } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect_order(*names)
      expect(response.body).to include(I18n.t(:notice_successful_update))
      html = Nokogiri::HTML(response.parsed_body).css("turbo-stream[action=update] template").map(&:inner_html).join
      fragment = Capybara.string(html)
      expect(fragment.all("[role='list'] > [role='listitem'] h4 a").map(&:text)).to eq(names[2, 2])
      expect(fragment).to have_link("1", href: types_path(page: 1, per_page: 2))
      expect(fragment).to have_link("3", href: types_path(page: 3, per_page: 2))
    end
  end

  [nil, "sideways", false, [], {}].each do |direction|
    it "rejects invalid direction #{direction.inspect}" do
      post move_types_path(types[3], page: 2, per_page: 2),
           params: { type: { move_to: direction } }, as: :json,
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect_order("A", "B", "C", "D", "E")
    end
  end

  it "keeps page context in the lazy menu forms" do
    get menu_type_path(types[2], page: 2, per_page: 2, expand: types[2].id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to have_css("form[action='#{move_types_path(types[2], page: 2, per_page: 2, expand: types[2].id)}']")
    expect(response.body).to have_css("input[name='type[move_to]'][value='higher']", visible: :all)
  end

  it "preserves variant membership and alphabetical order" do
    zeta = create(:type_variant, type: types[3], variant_name: "Zeta")
    alpha = create(:type_variant, type: types[3], variant_name: "Alpha")
    drop(types[3])

    expect(response).to have_http_status(:ok)
    expect(types[3].variants.non_default_variants.in_display_order).to eq([alpha, zeta])
    expect([alpha.reload.type_id, zeta.reload.type_id]).to eq([types[3].id, types[3].id])
  end

  context "without admin permission" do
    current_user { create(:user) }

    it "rejects dragging" do
      drop(types[3])

      expect(response).to have_http_status(:forbidden)
      expect_order("A", "B", "C", "D", "E")
    end

    it "rejects menu moves" do
      post move_types_path(types[3]), params: { type: { move_to: "highest" } }, as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect_order("A", "B", "C", "D", "E")
    end
  end
end
