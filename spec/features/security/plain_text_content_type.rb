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

RSpec.describe "Plain text content type XSS prevention", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:attachments) { Components::Attachments.new }
  let(:attachments_list) { Components::AttachmentsList.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/test.js") }

  before do
    login_as admin
  end

  it "allows accessing text/javascript files as inlinable plain text" do
    wp_page.visit_tab!(:files)
    attachments_list.wait_until_visible

    ##
    # Attach file manually
    attachments_list.expect_empty
    attachments.attach_file_on_input(image_fixture.path)
    attachments_list.expect_attached("test.js")

    expect(work_package.attachments.count).to eq 1
    attachment = work_package.attachments.first

    expect(attachment.content_type).to eq "text/x-javascript"
    expect(attachment).to be_inlineable

    visit home_path

    # Assume we have a HTML sanitation issue
    expect do
      accept_alert(wait: 1) do
        page.execute_script <<-JS
      const element = document.createElement('script')
      element.id = "testscript"
      element.src = '/api/v3/attachments/#{attachment.id}/content'
      document.body.appendChild(element);
        JS
      end
    end.to raise_error(Capybara::ModalNotFound)
  end
end
