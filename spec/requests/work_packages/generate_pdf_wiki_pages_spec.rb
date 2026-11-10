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

RSpec.describe "POST work package generate_pdf with wiki pages", :skip_csrf, type: :rails_request do
  shared_let(:provider) { create(:internal_wiki_provider) }
  shared_let(:project) { create(:project) }
  shared_let(:wiki) { create(:wiki, project:) }
  shared_let(:configured_page) do
    create(:wiki_page, wiki:, title: "Legal information", text: "The legal fineprint.")
  end

  shared_let(:other_project) { create(:project) }
  shared_let(:other_wiki) { create(:wiki, project: other_project) }
  shared_let(:secret_page) { create(:wiki_page, wiki: other_wiki, title: "Secret", text: "Leaked fineprint.") }

  shared_let(:work_package) { create(:work_package, project:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_work_packages export_work_packages] }) }

  before do
    variant = work_package.type_variant
    variant.pdf_export_templates.update_settings("artefact", "wiki_pages" => ["#{provider.id}:#{configured_page.id}"])
    variant.save!
  end

  def generate_pdf(wiki_pages)
    post "/work_packages/#{work_package.id}/generate_pdf",
         params: { template: "artefact", wiki_pages: }
  end

  def pdf_text = PDF::Inspector::Text.analyze(response.body).strings.join(" ")

  it "renders a configured page the user cannot read on its own" do
    generate_pdf(["#{provider.id}:#{configured_page.id}"])

    expect(response).to have_http_status(:ok)
    expect(pdf_text).to include("The legal fineprint.")
  end

  it "drops a forged reference to a page the user may not read" do
    generate_pdf(["#{provider.id}:#{secret_page.id}"])

    expect(response).to have_http_status(:ok)
    expect(pdf_text).not_to include("Leaked fineprint.")
  end
end
