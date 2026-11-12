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

RSpec.describe WorkPackageMailer do
  describe "#mentioned" do
    shared_let(:view_role) { create(:project_role, permissions: %i[view_work_packages]) }
    shared_let(:shared_project) { create(:project, public: false) }
    shared_let(:private_project) { create(:project, public: false) }
    shared_let(:author) do
      create(:user, member_with_roles: { shared_project => view_role, private_project => view_role })
    end
    shared_let(:recipient) { create(:user, member_with_roles: { shared_project => view_role }) }
    shared_let(:visible_recipient) do
      create(:user, member_with_roles: { shared_project => view_role, private_project => view_role })
    end
    shared_let(:referenced_type) { create(:type, name: "OrchidType") }
    shared_let(:referenced_status) { create(:status, name: "OrchidStatus") }
    shared_let(:referenced_work_package) do
      create(:work_package,
             project: private_project,
             type: referenced_type,
             status: referenced_status,
             subject: "Orchid bridge subject")
    end
    shared_let(:shared_work_package) { create(:work_package, project: shared_project, subject: "Shared topic") }

    let(:journal) do
      create(:work_package_journal,
             journable: shared_work_package,
             user: author,
             version: shared_work_package.journals.maximum(:version).to_i + 1,
             notes: "please review #{'###'}#{referenced_work_package.id}")
    end

    before do
      expect(WorkPackage.visible(author).where(id: referenced_work_package.id)).to exist
      expect(WorkPackage.visible(recipient).where(id: referenced_work_package.id)).not_to exist
      expect(WorkPackage.visible(visible_recipient).where(id: referenced_work_package.id)).to exist
    end

    context "with classic identifiers",
            with_settings: { work_packages_identifier: "classic" } do
      subject(:mail) { described_class.mentioned(recipient, journal) }

      it "keeps a bare reference and omits subject, type, and status the recipient cannot view" do
        body = mail.html_part.body.to_s

        expect(body).to include("##{referenced_work_package.id}")
        expect(body).not_to include(referenced_work_package.subject)
        expect(body).not_to include(referenced_type.name)
        expect(body).not_to include(referenced_status.name)
      end

      it "expands subject, type, and status when the recipient can view the referenced work package" do
        body = described_class.mentioned(visible_recipient, journal).html_part.body.to_s

        expect(body).to include(referenced_work_package.subject)
        expect(body).to include(referenced_type.name)
        expect(body).to include(referenced_status.name)
      end
    end
  end
end
