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

RSpec.describe Journal do
  it_behaves_like "acts_as_attachable included" do
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project:) }
    let(:model_instance) { create(:work_package_journal, journable: work_package, version: 2) }

    describe "#attachments_visible?" do
      context "with a internal journal" do
        let(:internal_journal) { build_stubbed(:work_package_journal, journable: work_package, internal: true) }

        context "with the user having the internal permission" do
          let(:user_with_internal_permission) do
            create(:user, member_with_permissions: { project => %i[view_work_packages view_internal_comments] })
          end

          let(:current_user) { user_with_internal_permission }

          before do
            login_as(current_user)
          end

          it "is visible" do
            expect(internal_journal).to be_attachments_visible
          end
        end

        context "with the user not having the internal permission" do
          it "returns false" do
            expect(internal_journal).not_to be_attachments_visible
          end
        end
      end

      context "with a non-project-member who has the work package shared with them" do
        let(:shared_user) { create(:user) }
        let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }

        before do
          create(:work_package_member, entity: work_package, user: shared_user,
                                       roles: [create(:view_work_package_role)])
          login_as(shared_user)
        end

        it "is visible" do
          expect(journal).to be_attachments_visible(shared_user)
        end

        context "when the journal is internal" do
          let(:journal) { create(:work_package_journal, journable: work_package, version: 2, internal: true) }

          it "is not visible without the internal comments permission" do
            expect(journal).not_to be_attachments_visible(shared_user)
          end
        end
      end
    end
  end

  describe "#visible?" do
    let(:work_package) { create(:work_package) }
    let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }

    let(:user_with_internal_permission) do
      create(:user,
             member_with_permissions: { work_package.project => %i[view_work_packages
                                                                   view_internal_comments] })
    end

    let(:user_with_view_work_packages_permission) do
      create(:user,
             member_with_permissions: { work_package.project => %i[view_work_packages] })
    end

    context "with a internal journal" do
      before do
        journal.update!(internal: true)
      end

      context "with the user having view permission for internal journals" do
        before do
          login_as(user_with_internal_permission)
        end

        it "is visible" do
          expect(journal).to be_visible
        end
      end

      context "with the user not having view permission for internal journals" do
        before do
          login_as(user_with_view_work_packages_permission)
        end

        it "is not visible" do
          expect(journal).not_to be_visible
        end
      end
    end

    context "with a journal that is not internal" do
      before do
        journal.update!(internal: false)
        login_as(user_with_view_work_packages_permission)
      end

      context "and the user has permission to view public journals" do
        it "is visible" do
          expect(journal).to be_visible
        end
      end
    end
  end

  describe "#journable" do
    it "raises no error on a new journal without a journable" do
      expect(described_class.new.journable)
        .to be_nil
    end
  end

  describe "#notifications" do
    let(:work_package) { create(:work_package) }
    let(:journal) { work_package.journals.first }
    let!(:notification) do
      create(:notification,
             journal:,
             resource: work_package)
    end

    it "has a notifications association" do
      expect(journal.notifications)
        .to contain_exactly(notification)
    end

    it "destroys the associated notifications upon journal destruction" do
      expect { journal.destroy }
        .to change(Notification, :count).from(1).to(0)
    end
  end

  describe "#create" do
    context "without a data foreign key" do
      subject { create(:work_package_journal, data: nil) }

      it "raises an error and does not create a database record" do
        expect { subject }
          .to raise_error(ActiveRecord::NotNullViolation)

        expect(described_class.count)
          .to eq 0
      end
    end
  end
end
