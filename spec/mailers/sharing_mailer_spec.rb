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

RSpec.describe SharingMailer do
  let(:project) { build_stubbed(:project) }
  let(:work_package) do
    build_stubbed(:work_package,
                  type: build_stubbed(:type_standard),
                  author: build_stubbed(:user),
                  project:)
  end
  let(:shared_with_user) { build_stubbed(:user) }
  let(:roles) { [build_stubbed(:comment_work_package_role)] }
  let(:work_package_member) do
    build_stubbed(:work_package_member,
                  entity: work_package,
                  user: shared_with_user,
                  roles:)
  end

  let(:current_user) { build_stubbed(:user) }

  describe "#shared_work_package" do
    subject(:mail) do
      described_class.shared_work_package(current_user, work_package_member)
    end

    it "addresses the mail to the member's principal" do
      expect(mail.to)
        .to contain_exactly(shared_with_user.mail)
    end

    it "sets the appropriate subject" do
      expect(mail.subject)
        .to eq(I18n.t("mail.sharing.work_packages.subject",
                      id: work_package.id))
    end

    it "has a project header" do
      expect(mail["X-OpenProject-Project"].value)
        .to eq(project.identifier)
    end

    it "has a work package id header" do
      expect(mail["X-OpenProject-WorkPackage-Id"].value)
        .to eq(work_package.id.to_s)
    end

    it "has a type header" do
      expect(mail["X-OpenProject-Type"].value)
        .to eq("WorkPackage")
    end

    it "has a message id header" do
      Timecop.freeze(Time.current) do
        expect(mail.message_id)
          .to eq("op.member-#{work_package_member.id}.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{current_user.id}@example.net")
      end
    end
  end
end
