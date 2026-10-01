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

require "rails_helper"

RSpec.describe "External links", :js do
  let(:user) { create(:user) }

  before do
    login_as user
  end

  it "sets ARIA describedby on external links" do
    visit "/"

    expect(page).to have_link target: "_blank", accessible_description: "Open link in a new tab"
    expect(page.all(:link, target: "_blank")).to all match_selector(:link, accessible_description: "Open link in a new tab")
  end

  it "updates external links to open in a new tab and sets rel attributes" do
    visit "/"

    page.execute_script <<~JS
      const link = document.createElement('a');
      link.href = 'https://example.com';
      link.textContent = 'External Example';
      document.body.appendChild(link);
    JS

    link = page.find_link("External Example", href: "https://example.com", match: :first)

    # Verify accessibility and security attributes
    expect(link[:target]).to eq("_blank")
    expect(link[:rel]).to include("noopener")
    expect(link[:rel]).to include("noreferrer")

    # It should also get the accessibility description
    expect(link[:"aria-describedby"]).to include("open-blank-target-link-description")
  end

  it "does not modify links with empty href or download attribute" do
    visit "/"

    page.execute_script <<~JS
      const emptyLink = document.createElement('a');
      emptyLink.href = '';
      emptyLink.textContent = 'Empty link';
      document.body.appendChild(emptyLink);

      const downloadLink = document.createElement('a');
      downloadLink.href = '/files/sample.pdf';
      downloadLink.download = 'sample.pdf';
      downloadLink.textContent = 'Download PDF';
      document.body.appendChild(downloadLink);
    JS

    empty_link = find_link("Empty link", href: "", match: :first)
    download_link = find_link("Download PDF", href: "/files/sample.pdf", match: :first)

    # The controller should NOT modify these links
    expect(empty_link[:target]).to be_in([nil, ""])
    expect(empty_link[:rel]).to be_nil.or eq("")
    expect(empty_link[:"aria-describedby"]).to be_nil.or eq("")

    expect(download_link[:target]).to be_in([nil, ""])
    expect(download_link[:rel]).to be_nil.or eq("")
    expect(download_link[:"aria-describedby"]).to be_nil.or eq("")
  end

  it 'adds aria-describedby to links with target="_blank"' do
    visit "/"

    page.execute_script <<~JS
      const blankLink = document.createElement('a');
      blankLink.href = '/internal-page';
      blankLink.target = '_blank';
      blankLink.textContent = 'Opens in new tab';
      document.body.appendChild(blankLink);
    JS

    link = find_link("Opens in new tab", href: "/internal-page")

    expect(link[:target]).to eq("_blank")
    expect(link[:"aria-describedby"]).to include("open-blank-target-link-description")
  end
end
