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

RSpec.describe AnnouncementMailer do
  let(:announcement_subject) { "Some subject" }
  let(:recipient) { build_stubbed(:user) }
  let(:announcement_body) { "Some body text" }

  describe "#announce" do
    subject(:mail) do
      described_class.announce(recipient,
                               subject: announcement_subject,
                               body: announcement_body)
    end

    it "has a subject" do
      expect(mail.subject)
        .to eq announcement_subject
    end

    it "includes the body" do
      expect(mail.body.encoded)
        .to include(announcement_body)
    end

    it "includes the subject in the body as well" do
      expect(mail.body.encoded)
        .to include announcement_subject
    end

    it "sends to the recipient" do
      expect(mail.to)
        .to contain_exactly(recipient.mail)
    end

    context "when user is locked" do
      let(:recipient) { build_stubbed(:user, status: Principal.statuses[:locked]) }

      it "does not send an email" do
        expect(mail.subject).to be_nil
        expect(mail.to).to be_nil
      end
    end

    describe "rendering a body that references a work package" do
      shared_let(:persisted_project) { create(:project, identifier: "announceproj") }
      shared_let(:persisted_recipient) { create(:admin) }
      shared_let(:referenced_wp) { create(:work_package, project: persisted_project) }

      let(:html_body) do
        User.execute_as(persisted_recipient) do
          described_class.announce(persisted_recipient,
                                   subject: announcement_subject,
                                   body: "see ##{referenced_wp.id}")
                         .html_part.body.to_s
        end
      end

      context "with classic mode",
              with_settings: { work_packages_identifier: "classic" } do
        it "renders the numeric reference as an absolute work-package link" do
          expect(html_body).to match(%r{href="http[^"]*/work_packages/#{referenced_wp.id}"})
        end
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        before do
          referenced_wp.update_columns(identifier: "ANNOUNCEPROJ-1", sequence_number: 1)
        end

        it "renders the formatted_id as an absolute work-package link" do
          expect(html_body).to include("ANNOUNCEPROJ-1")
          expect(html_body).to match(%r{href="http[^"]*/work_packages/ANNOUNCEPROJ-1"})
        end
      end
    end
  end
end
