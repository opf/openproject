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
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::ProjectStorages::OAuthAccessGrantedModalComponent, type: :component do # rubocop:disable RSpec/SpecFilePathFormat
  let(:oauth_client) { build_stubbed(:oauth_client) }
  let(:storage) { build_stubbed(:nextcloud_storage, oauth_client:) }

  before do
    allow(OAuthClientToken).to receive(:exists?).and_return(true)
  end

  it "renders a success modal" do
    render_inline(described_class.new(storage:))

    expect(page).to have_css(
      "h1.sr-only",
      text: "Access granted. You are now ready to use #{storage.name}"
    )

    expect(page).to have_content("Access granted")
    expect(page).to have_content("You are now ready to use #{storage.name}")

    expect(page).to have_button("Close")

    aggregate_failures "checks that the current user has an oauth token" do
      expect(OAuthClientToken).to have_received(:exists?)
        .with(user: User.current, oauth_client: storage.oauth_client)
    end
  end
end
