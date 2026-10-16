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

RSpec.describe API::V3::Labels::LabelCollectionRepresenter do
  include API::V3::Utilities::PathHelper

  let(:self_base_link) { api_v3_paths.labels }
  let(:labels) do
    build_stubbed_list(:label, 3).tap do |labels|
      without_partial_double_verification do
        allow(labels).to receive_messages(offset: labels, limit: labels, count: total)
      end
    end
  end
  let(:representer) do
    described_class.new(labels,
                        self_link: self_base_link,
                        page:,
                        per_page: page_size,
                        current_user: instance_double(User))
  end
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 2 }
  let(:actual_count) { 3 }
  let(:collection_inner_type) { "Label" }

  context "when listing" do
    subject(:collection) { representer.to_json }

    it_behaves_like "offset-paginated APIv3 collection"
  end
end
