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

RSpec.describe WorkPackage::PDFExport::WikiPagesResolver do
  shared_let(:provider) { create(:internal_wiki_provider) }

  shared_let(:open_project) { create(:project, name: "Open") }
  shared_let(:open_wiki) { create(:wiki, project: open_project) }
  shared_let(:open_page) { create(:wiki_page, wiki: open_wiki, title: "Open page") }

  shared_let(:secret_project) { create(:project, name: "Secret") }
  shared_let(:secret_wiki) { create(:wiki, project: secret_project) }
  shared_let(:secret_page) { create(:wiki_page, wiki: secret_wiki, title: "Secret page") }

  shared_let(:role) { create(:project_role, permissions: %i[view_wiki_pages]) }
  shared_let(:user) { create(:user, member_with_roles: { open_project => role }) }

  def ref(page) = "#{provider.id}:#{page.id}"

  def resolve(submitted:, configured:)
    described_class.new(submitted:, configured:, user:).call
  end

  it "uses the configured list verbatim when nothing was submitted" do
    expect(resolve(submitted: nil, configured: [ref(secret_page), ref(open_page)]))
      .to eq [secret_page, open_page]
  end

  it "keeps a configured page the user cannot read" do
    expect(resolve(submitted: [ref(secret_page)], configured: [ref(secret_page)])).to eq [secret_page]
  end

  it "lets the submitted order win over the configured one" do
    configured = [ref(secret_page), ref(open_page)]

    expect(resolve(submitted: [ref(open_page), ref(secret_page)], configured:)).to eq [open_page, secret_page]
  end

  it "keeps a self added page the user may read" do
    expect(resolve(submitted: [ref(open_page)], configured: [])).to eq [open_page]
  end

  it "drops a forged reference that is neither configured nor visible" do
    expect(resolve(submitted: [ref(secret_page), ref(open_page)], configured: [])).to eq [open_page]
  end

  it "drops a submitted page the user removed from the configured list" do
    expect(resolve(submitted: [ref(open_page)], configured: [ref(secret_page), ref(open_page)])).to eq [open_page]
  end

  it "drops unparseable and duplicated references" do
    expect(resolve(submitted: ["", "garbage", ref(open_page), ref(open_page)], configured: [])).to eq [open_page]
  end

  it "drops a reference qualified with another provider" do
    expect(resolve(submitted: ["#{provider.id + 1}:#{open_page.id}"], configured: [])).to be_empty
  end

  it "drops a page whose project was archived" do
    open_project.update!(active: false)

    expect(resolve(submitted: nil, configured: [ref(open_page)])).to be_empty
  end

  it "drops a page that no longer exists" do
    expect(resolve(submitted: nil, configured: ["#{provider.id}:0"])).to be_empty
  end
end
