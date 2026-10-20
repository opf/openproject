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

require "rails_helper"

RSpec.describe "POST work package generate_pdf", :skip_csrf, type: :rails_request do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, description: "honorificabilitudinitatibus") }
  let(:permissions) { %i[view_work_packages export_work_packages] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  before { allow(Hyphen).to receive(:new).and_call_original }

  def generate_pdf(hyphenation_language:)
    post "/work_packages/#{work_package.id}/generate_pdf",
         params: { template: "attributes", hyphenation: "1", hyphenation_language: }
  end

  context "with a supported hyphenation language" do
    before { generate_pdf(hyphenation_language: "de") }

    it "hyphenates with that language", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(Hyphen).to have_received(:new).with("de", true)
    end
  end

  context "with an unsupported hyphenation language" do
    before { generate_pdf(hyphenation_language: "not-a-language") }

    it "generates the PDF without hyphenation", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(Hyphen).not_to have_received(:new)
    end
  end
end
