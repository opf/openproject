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
#
require "spec_helper"

RSpec.describe WorkPackages::ActivitiesTab::Journals::RevisionComponent, type: :component do
  describe "#remove_email_addresses" do
    let(:component) { described_class.new(changeset: build(:changeset), filter: nil) }

    def render_committer(committer)
      component.remove_email_addresses(committer)
    end

    it "escapes HTML tags" do
      committer = "OP User <o.p@email.local><script>alert('xss')</script>"
      result = render_committer(committer)

      expect(result.to_s).to eq("OP User")
      expect(result.to_html).not_to include("<script>")
    end

    it "removes email addresses" do
      committer = "OP User <o.p@email.local>"
      result = render_committer(committer)
      expect(result.to_s).to eq("OP User")
    end

    it "handles committer names without email" do
      committer = "OP User"
      result = render_committer(committer)
      expect(result.to_s).to eq("OP User")
    end

    it "handles empty committer names" do
      committer = ""
      result = render_committer(committer)
      expect(result.to_s).to eq("")
    end

    it "handles nil committer names" do
      committer = nil
      result = render_committer(committer)
      expect(result.to_s).to eq("")
    end

    it "handles committer names with special characters" do
      committer = "OP User <o.p@email.local> & Co."
      result = render_committer(committer)
      expect(result.to_s).to eq("OP User  &amp;amp; Co.")
    end

    it "handles committer names with multiple emails" do
      committer = "OP User <o.p@email.local> <another.email@example.com>"
      result = render_committer(committer)
      expect(result.to_s).to eq("OP User")
    end
  end
end
