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

RSpec.describe Notifications::Scopes::Visible do
  describe ".visible" do
    subject(:scope) { Notification.visible(user) }

    let(:user) do
      create(:user,
             member_with_permissions: { project => permissions })
    end

    let(:notification) do
      create(:notification,
             resource: work_package,
             recipient: notification_recipient)
    end
    let(:notification_recipient) { user }
    let(:permissions) { %i[view_work_packages] }
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project:) }

    let!(:notifications) { notification }

    shared_examples_for "is empty" do
      it "is empty" do
        expect(scope)
          .to be_empty
      end
    end

    context "with the user being recipient and being allowed to see the work package" do
      it "returns the notification" do
        expect(scope)
          .to contain_exactly(notification)
      end
    end

    context "with the user being recipient and not being allowed to see the work package" do
      let(:permissions) { [] }

      it_behaves_like "is empty"
    end

    context "with the user not being recipient but being allowed to see the work package" do
      let(:notification_recipient) { create(:user) }

      it_behaves_like "is empty"
    end

    context "for a document notification" do
      let(:project) { create(:project, enabled_module_names: %w[work_package_tracking documents]) }
      let(:document) { create(:document, project:) }
      let(:notification) do
        create(:notification,
               resource: document,
               journal: nil,
               recipient: notification_recipient)
      end
      let(:permissions) { %i[view_documents] }

      context "with the user being recipient and being allowed to see the document" do
        it "returns the notification" do
          expect(scope)
            .to contain_exactly(notification)
        end
      end

      context "with the user being recipient and not being allowed to see the document" do
        let(:permissions) { %i[view_work_packages] }

        it_behaves_like "is empty"
      end

      context "with the user being recipient and the documents module being disabled" do
        let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }

        it_behaves_like "is empty"
      end

      context "with the user not being recipient but being allowed to see the document" do
        let(:notification_recipient) { create(:user, member_with_permissions: { project => permissions }) }

        it_behaves_like "is empty"
      end
    end

    context "with work package and document notifications" do
      let(:project) { create(:project, enabled_module_names: %w[work_package_tracking documents]) }
      let(:permissions) { %i[view_work_packages view_documents] }
      let(:document) { create(:document, project:) }
      let(:document_notification) do
        create(:notification,
               resource: document,
               journal: nil,
               recipient: user)
      end
      let(:other_project) { create(:project, enabled_module_names: %w[work_package_tracking documents]) }
      let(:invisible_work_package_notification) do
        create(:notification,
               resource: create(:work_package, project: other_project),
               recipient: user)
      end
      let(:invisible_document_notification) do
        create(:notification,
               resource: create(:document, project: other_project),
               journal: nil,
               recipient: user)
      end
      let(:other_recipient_document_notification) do
        create(:notification,
               resource: document,
               journal: nil,
               recipient: create(:user, member_with_permissions: { project => permissions }))
      end

      let!(:notifications) do
        [notification,
         document_notification,
         invisible_work_package_notification,
         invisible_document_notification,
         other_recipient_document_notification]
      end

      it "returns the notifications of the recipient for visible resources only" do
        expect(scope)
          .to contain_exactly(notification, document_notification)
      end

      it "returns the same when chained onto another scope" do
        expect(Notification.where(read_ian: false).visible(user))
          .to contain_exactly(notification, document_notification)
      end
    end
  end
end
