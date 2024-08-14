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

RSpec.describe Storages::Admin::Storages::OAuthAccessGrantNudgeModalComponent, type: :component do # rubocop:disable RSpec/SpecFilePathFormat
  let(:storage) { build_stubbed(:nextcloud_storage) }

  it "renders the nudge modal" do
    render_inline(described_class.new(storage:))

    expect(page).to have_css('[role="alert"]', text: "One more step...", aria: { live: :assertive })
    expect(page).to have_test_selector(
      "oauth-access-grant-nudge-modal-body",
      text: "To get access to the project folder you need to login to #{storage.name}."
    )

    expect(page).to have_button("I will do it later")
    expect(page).to have_button("Login", aria: { label: "Login to #{storage.name}" })
  end

  context "with no storage" do
    it "does not render" do
      render_inline(described_class.new(storage: nil))

      expect(page.text).to be_empty
    end
  end
end
