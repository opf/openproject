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

RSpec.describe MailHandler do
  # we need these run first so the anonymous and system users are created and
  # there is a default work package priority to save any work packages
  shared_let(:anno_user) { User.anonymous }
  shared_let(:system_user) { User.system }
  shared_let(:priority_low) { create(:priority_low, name: "Low", is_default: true) }

  shared_let(:project) { create(:valid_project, identifier: "onlinestore", name: "OnlineStore", public: false) }

  before do
    allow(UserMailer)
      .to receive(:incoming_email_error)
      .and_return instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
  end

  after do
    User.current = nil
    allow(Setting).to receive(:default_language).and_return("en")
  end

  shared_context "for wp_on_given_project" do
    let(:permissions) { %i[add_work_packages assign_versions work_package_assigned] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_on_given_project.eml", **submit_options)
    end
  end

  shared_context "for wp_on_given_project_case_insensitive" do
    let(:permissions) { %i[add_work_packages assign_versions] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { { allow_override: "version" } }

    subject do
      submit_email("wp_on_given_project_case_insensitive.eml", **submit_options)
    end
  end

  shared_context "for wp on given project group assignment" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:group) do
      create(:group,
             lastname: "A-Team",
             member_with_permissions: { project => [:work_package_assigned] })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_on_given_project_group_assignment.eml", **submit_options)
    end
  end

  shared_context "with a reply to a wp mention with quotes above" do
    let(:permissions) { %i[edit_work_packages view_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             member_with_permissions: { project => permissions })
    end

    let!(:work_package) do
      create(:work_package,
             id: 2,
             project:) do |wp|
        wp.journals.last.update_column(:id, 891223)
      end
    end

    subject do
      submit_email("wp_reply_with_quoted_reply_above.eml")
    end
  end

  shared_context "with wp create with cc" do
    let(:permissions) { %i[add_work_packages view_work_packages add_work_package_watchers] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:cc_user) do
      create(:user,
             mail: "dlopper@somenet.foo",
             firstname: "D",
             lastname: "Lopper",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { { issue: { project: project.identifier } } }

    subject do
      submit_email("ticket_with_cc.eml", **submit_options)
    end
  end

  shared_context "with a reply to a wp mention" do
    let(:permissions) { %i[add_work_package_notes view_work_packages] }
    let!(:user) do
      create(:user,
             mail: "j.doe@openproject.org",
             member_with_permissions: { project => permissions })
    end

    let!(:work_package) do
      create(:work_package,
             subject: "Some subject of the bug",
             id: 39733,
             project:) do |wp|
        wp.journals.last.update_column(:id, 99999999)
      end
    end

    subject do
      submit_email("wp_mention_reply.eml")
    end
  end

  shared_context "with a reply to a wp mention with attributes" do
    let(:permissions) { %i[add_work_package_notes view_work_packages edit_work_packages work_package_assigned] }
    let(:role) do
      create(:project_role, permissions:)
    end
    let!(:user) do
      create(:user,
             mail: "j.doe@openproject.org",
             member_with_roles: { project => role })
    end

    let!(:work_package) do
      create(:work_package,
             subject: "Some subject of the bug",
             id: 39733,
             project:,
             status: original_status) do |wp|
        wp.journals.last.update_column(:id, 99999999)
      end
    end
    let!(:original_status) do
      create(:default_status)
    end
    let!(:resolved_status) do
      create(:status,
             name: "Resolved") do |status|
        create(:workflow,
               old_status: original_status,
               new_status: status,
               role:,
               type: work_package.type)
      end
    end
    let!(:other_user) do
      create(:user,
             mail: "jsmith@somenet.foo",
             member_with_roles: { project => [role] })
    end
    let!(:float_cf) do
      create(:float_wp_custom_field,
             name: "float field") do |cf|
        project.work_package_custom_fields << cf
        work_package.type.custom_fields << cf
      end
    end

    subject do
      submit_email("wp_mention_reply_with_attributes.eml")
    end
  end

  shared_context "with a reply to a message" do
    let(:permissions) { %i[view_messages add_messages] }
    let!(:user) do
      create(:user,
             mail: "j.doe@openproject.org",
             member_with_permissions: { project => permissions })
    end

    let!(:message) do
      create(:message,
             id: 70917,
             forum: create(:forum, project:)) do |wp|
        wp.journals.last.update_column(:id, 99999999)
      end
    end

    subject do
      submit_email("message_reply.eml")
    end
  end

  shared_context "with a new work package with attributes" do
    let(:permissions) { %i[add_work_packages assign_versions work_package_assigned] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:feature_type) do
      create(:type,
             name: "Feature request") do |type|
        project.types << type
      end
    end
    let!(:stock_category) do
      project.categories.create(name: "Stock management")
    end
    let!(:urgent_priority) do
      create(:priority_urgent)
    end
    let!(:high_priority) do
      create(:priority_high)
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_attributes.eml", **submit_options)
    end
  end

  shared_context "with a new work package with attributes with additional spaces" do
    let(:permissions) { %i[add_work_packages assign_versions work_package_assigned] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:feature_type) do
      create(:type,
             name: "Feature request") do |type|
        project.types << type
      end
    end
    let!(:stock_category) do
      project.categories.create(name: "Stock management")
    end
    let!(:urgent_priority) do
      create(:priority_urgent)
    end
    let!(:high_priority) do
      create(:priority_high)
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_spaces_between_attribute_and_separator.eml", **submit_options)
    end
  end

  shared_context "with a new work package with attributes in japanese" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:japanese_type) do
      create(:type,
             name: "開発") do |type|
        project.types << type
      end
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_attributes_japanese.eml", **submit_options)
    end
  end

  shared_context "with a new work package with attachment" do
    # The work package is created first and only then the attachment is added.
    let(:permissions) { %i[add_work_packages add_work_package_attachments] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_attachment.eml", **submit_options)
    end
  end

  shared_context "with a new work package with attachment in apple format" do
    # The work package is created first and only then the attachment is added.
    let(:permissions) { %i[add_work_packages add_work_package_attachments] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_attachment_apple.eml", **submit_options)
    end
  end

  shared_context "with a new work package with a custom field" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let!(:custom_field) do
      create(:string_wp_custom_field, name: "Searchable field") do |cf|
        project.work_package_custom_fields << cf
        project.types.first.custom_fields << cf
      end
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_custom_field.eml", **submit_options)
    end
  end

  shared_context "with a new work package with invalid attributes" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_invalid_attributes.eml", **submit_options)
    end
  end

  shared_context "with a new work package with localized attributes" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             language: "de",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    let!(:feature_type) do
      create(:type,
             name: "Feature request") do |type|
        project.types << type
      end
    end
    let!(:stock_category) do
      project.categories.create(name: "Stock management")
    end
    let!(:urgent_priority) do
      create(:priority_urgent)
    end

    subject do
      submit_email("wp_with_localized_attributes.eml", **submit_options)
    end
  end

  shared_context "with a new work package with iso 8859 1 subject" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             language: "de",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_iso_8859_1_subject.eml", **submit_options)
    end
  end

  shared_context "with a new work package with long subject" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             language: "de",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_long_subject.eml", **submit_options)
    end
  end

  shared_context "with a new work package with html only description" do
    let(:permissions) { %i[add_work_packages] }
    let!(:user) do
      create(:user,
             mail: "JSmith@somenet.foo",
             firstname: "John",
             lastname: "Smith",
             language: "de",
             member_with_permissions: { project => permissions })
    end
    let(:submit_options) { {} }

    subject do
      submit_email("wp_with_html_only_description.eml", **submit_options)
    end
  end

  shared_context "with a new work package with the sender fullname in utf-8" do
    let(:submit_options) { {} }

    before do
      ProjectRole.non_member.update_attribute :permissions, [:add_work_packages]
      project.update_attribute :public, true
    end

    subject do
      submit_email("wp_with_utf8_fullname_of_sender.eml", **submit_options)
    end
  end

  describe "#receive" do
    shared_examples_for "work package created" do
      it "creates the work package" do
        expect(subject)
          .to be_a(WorkPackage)

        expect(subject)
          .to be_persisted
      end
    end

    shared_examples_for "journal created" do
      it "creates the journal" do
        expect(subject)
          .to be_a(Journal)

        expect(subject)
          .to be_persisted
      end
    end

    context "when sending a mail not as a reply" do
      context "for a given project" do
        let(:type) { project.types.first }
        let!(:status) { create(:status, name: "Resolved", workflow_for_type: type) }
        let!(:version) { create(:version, name: "alpha", project:) }

        include_context "for wp_on_given_project" do
          let(:submit_options) { { allow_override: "version" } }
        end

        it_behaves_like "work package created"

        it "sets the referenced project" do
          expect(subject.project)
            .to eql(project)
        end

        it "sets the first type in the project" do
          expect(subject.type)
            .to eql(type)
        end

        it "sets the subject" do
          expect(subject.subject)
            .to eql("New ticket on a given project")
        end

        it "sets the sender as the author" do
          expect(subject.author)
            .to eql(user)
        end

        it "set the description" do
          expect(subject.description)
            .to include("Lorem ipsum dolor sit amet, consectetuer adipiscing elit.")
        end

        it "sets the start date" do
          expect(subject.start_date.to_s)
            .to eql("2010-01-01")
        end

        it "sets the due date" do
          expect(subject.due_date.to_s)
            .to eql("2010-12-31")
        end

        it "sets the accountable" do
          expect(subject.responsible)
            .to eql(user)
        end

        it "sets the assignee" do
          expect(subject.assigned_to)
            .to eql(user)
        end

        it "sets the status" do
          expect(subject.status)
            .to eql(status)
        end

        it "sets the version" do
          expect(subject.version)
            .to eql(version)
        end

        it "sets the estimated_hours" do
          expect(subject.estimated_hours)
            .to be(2.5)
        end

        it "sets the done_ratio" do
          expect(subject.done_ratio)
            .to be(30)
        end

        it "removes keywords" do
          expect(subject.description)
            .not_to match(/^Project:/i)

          expect(subject.description)
            .not_to match(/^Status:/i)

          expect(subject.description)
            .not_to match(/^Start Date:/i)
        end

        it "sends notifications to watching users" do
          # User gets all updates
          user = create(:user,
                        member_with_permissions: { project => %i(view_work_packages) },
                        notification_settings: [build(:notification_setting, all: true)])

          expect do
            perform_enqueued_jobs do
              subject
            end
          end.to change(Notification.where(recipient: user), :count).by(1)
        end

        it "does not send an error reply email" do
          subject # send mail

          expect(UserMailer).not_to have_received(:incoming_email_error)
        end
      end

      context "for a given project with a default type" do
        let(:default_type) do
          create(:type, is_default: true) do |t|
            project.types << t
          end
        end

        include_context "for wp_on_given_project" do
          let(:submit_options) { { issue: { type: default_type.name } } }
        end

        it_behaves_like "work package created"

        it "sets the default type" do
          expect(subject.type.name)
            .to eql(default_type.name)
        end
      end

      context "for a given project with a locked user" do
        let!(:status) { create(:status, name: "Resolved") }

        before do
          user.locked!
        end

        include_context "for wp_on_given_project"

        it "does not create the work package" do
          expect { subject }
            .not_to change(WorkPackage, :count)
        end
      end

      context "for a given project with group assignment" do
        include_context "for wp on given project group assignment"

        it_behaves_like "work package created"

        it "sets the accountable to the group" do
          expect(subject.responsible)
            .to eql(group)
        end

        it "sets the assignee to the group" do
          expect(subject.assigned_to)
            .to eql(group)
        end
      end

      context "for an email by unknown user" do
        context "with unknown_user: 'create'" do
          it "adds a work_package by create user on public project" do
            ProjectRole.non_member.update_attribute :permissions, [:add_work_packages]
            project.update_attribute :public, true
            expect do
              work_package = submit_email("ticket_by_unknown_user.eml", issue: { project: "onlinestore" }, unknown_user: "create")
              work_package_created(work_package)
              expect(work_package.author).to be_active
              expect(work_package.author.mail).to eq("john.doe@somenet.foo")
              expect(work_package.author.firstname).to eq("John")
              expect(work_package.author.lastname).to eq("Doe")

              # account information
              perform_enqueued_jobs

              email = ActionMailer::Base.deliveries.first
              expect(email).not_to be_nil
              expect(email.subject).to eq(I18n.t("mail_subject_register", value: Setting.app_title))
              login = email.body.encoded.match(/\* Username: (\S+)\s?$/)[1]
              password = email.body.encoded.match(/\* Password: (\S+)\s?$/)[1]

              # Can't log in here since randomly assigned password must be changed
              found_user = User.find_by(login:)
              expect(work_package.author).to eq(found_user)
              expect(found_user).to be_check_password(password)
            end.to change(User, :count).by(1)
          end
        end

        context "with unknown_user: 'create' and an utf8 encoded fullname" do
          include_context "with a new work package with the sender fullname in utf-8"
          let(:submit_options) { { issue: { project: "onlinestore" }, unknown_user: "create" } }

          it_behaves_like "work package created"

          it "adds the user with decoded fullname" do
            expect do
              expect(subject.author).to be_active
              expect(subject.author.mail).to eq("foo@example.org")
              expect(subject.author.firstname).to eq("\xc3\x84\xc3\xa4".force_encoding("UTF-8"))
              expect(subject.author.lastname).to eq("\xc3\x96\xc3\xb6".force_encoding("UTF-8"))
            end.to change(User, :count).by(1)
          end
        end

        context "with unknown_user: nil (default)" do
          let(:results) { [] }

          before do
            results << submit_email(
              "ticket_by_unknown_user.eml",
              issue: { project: project.identifier },
              unknown_user: nil
            )
          end

          it "ignores the email" do
            expect(results).to eq [false]
          end

          it "does not respond with an error email" do
            expect(UserMailer).not_to have_received(:incoming_email_error)
          end
        end

        context "with unknown_user: 'accept' and permission check present" do
          let(:expected) do
            "MailHandler: work_package could not be created by Anonymous due to " \
              '#["Type was attempted to be written but is not writable.", ' \
              '"Project was attempted to be written but is not writable.", ' \
              '"Subject was attempted to be written but is not writable.", ' \
              '"Description was attempted to be written but is not writable.", ' \
              '"may not be accessed."]'
          end
          let(:permission) { nil }

          subject(:work_package) do
            submit_email(
              "ticket_by_unknown_user.eml",
              issue: { project: project.identifier },
              unknown_user: "accept"
            )
          end

          before do
            allow(Rails.logger).to receive(:error).with(expected)
            ProjectRole.anonymous.add_permission!(permission) if permission
          end

          context "with anonymous lacking permissions" do
            before do
              work_package
            end

            it "rejects the email" do
              expect(work_package).to be false
            end

            it "logs the error" do
              expect(Rails.logger).to have_received(:error).with(expected)
            end

            context "with report_incoming_email_errors true (default)" do
              it "responds with an error email" do
                expect(UserMailer).to have_received(:incoming_email_error) do |user, mail, logs|
                  expect(user).to eq anno_user
                  expect(mail[:subject]).to eq "Ticket by unknown user"
                  expect(logs).to eq [expected.sub(/^MailHandler/, "error")]
                end
              end
            end

            context "with report_incoming_email_errors false", with_settings: { report_incoming_email_errors: false } do
              it "does not respond with an error email" do
                expect(UserMailer).not_to have_received(:incoming_email_error)
              end
            end
          end

          context "with anonymous having permissions in a public project" do
            let(:permission) { :add_work_packages }

            before do
              project.update_attribute(:public, true)
            end

            it_behaves_like "work package created"

            it "sets the author to anonymous" do
              expect(work_package.author)
                .to eql User.anonymous
            end

            it "creates no user" do
              expect { work_package }
                .not_to change(User, :count)
            end
          end

          context "with anonymous having permissions in a private project" do
            let(:permission) { :add_work_packages }

            before do
              project.update_attribute(:public, false)
            end

            it "creates no work package" do
              expect { work_package }
                .not_to change(WorkPackage, :count)
            end

            it "creates no user" do
              expect { work_package }
                .not_to change(User, :count)
            end
          end
        end

        context "for unknown_user: 'accept' and no_permission_check" do
          subject(:work_package) do
            submit_email "ticket_by_unknown_user.eml",
                         issue: { project: project.identifier },
                         unknown_user: "accept",
                         no_permission_check: 1
          end

          it_behaves_like "work package created"

          it "sets the author to anonymous" do
            expect(work_package.author).to eq(User.anonymous)
          end
        end

        context "for unknown_user: 'accept' and without from header" do
          subject(:work_package) do
            ProjectRole.anonymous.add_permission!(:add_work_packages)

            submit_email "wp_without_from_header.eml",
                         issue: { project: project.identifier },
                         unknown_user: "accept"
          end

          it "creates no work package" do
            expect { work_package }
              .not_to change(WorkPackage, :count)
          end
        end

        context "for unknown_user: 'accept' and without permission checks and without from header" do
          subject(:work_package) do
            submit_email "wp_without_from_header.eml",
                         issue: { project: project.identifier },
                         unknown_user: "accept",
                         no_permission_check: 1
          end

          it_behaves_like "work package created"

          it "sets the author to anonymous" do
            expect(work_package.author).to eq(User.anonymous)
          end
        end
      end

      context "for email from emission address", with_settings: { mail_from: "openproject@example.net" } do
        before do
          ProjectRole.non_member.add_permission!(:add_work_packages)
        end

        subject do
          project.update(public: true)
          submit_email("ticket_from_emission_address.eml",
                       issue: { project: project.identifier },
                       unknown_user: "create")
        end

        it "returns false" do
          expect(subject).to be_falsey
        end

        it "does not create the user" do
          expect { subject }
            .not_to(change(User, :count))
        end

        it "does not create the work_package" do
          expect { subject }
            .not_to(change(WorkPackage, :count))
        end

        it "does not result in an error email response" do
          subject # send email

          expect(UserMailer).not_to have_received(:incoming_email_error)
        end
      end

      context "for wp with status" do
        let(:type) { project.types.first }
        let!(:status) { create(:status, name: "Resolved", workflow_for_type: type) }

        # This email contains: 'Project: onlinestore' and 'Status: Resolved'
        include_context "for wp_on_given_project"

        it_behaves_like "work package created"

        it "assigns the status to the created work package" do
          expect(subject.status)
            .to eql(status)
        end
      end

      context "for wp with status case insensitive" do
        let(:type) { project.types.first }
        let!(:status) { create(:status, name: "Resolved", workflow_for_type: type) }
        let!(:version) { create(:version, name: "alpha", project:) }

        # This email contains: 'Project: onlinestore' and 'Status: resolved'
        include_context "for wp_on_given_project_case_insensitive"

        it_behaves_like "work package created"

        it "assigns the status to the created work package" do
          expect(subject.status).to eq(status)
          expect(subject.version).to eq(version)
          expect(subject.priority).to eq priority_low
        end
      end

      context "for wp with cc" do
        include_context "with wp create with cc"

        it_behaves_like "work package created"

        it "assigns cc and author as watcher" do
          expect(subject.watcher_users)
            .to contain_exactly(user, cc_user)
        end
      end

      context "for a wp overriding attributes" do
        include_context "with a new work package with attributes"
        let(:submit_options) { { allow_override: "type,category,priority" } }

        it_behaves_like "work package created"

        it "sets the provided attributes" do
          expect(subject.project)
            .to eql project

          expect(subject.type)
            .to eql feature_type

          expect(subject.category)
            .to eql stock_category

          expect(subject.priority)
            .to eql urgent_priority
        end
      end

      context "for a wp overriding attributes partially" do
        include_context "with a new work package with attributes"
        let(:submit_options) { { issue: { priority: "High" }, allow_override: ["type"] } }

        it_behaves_like "work package created"

        it "sets the provided attributes only to the extend allowed and uses default" do
          expect(subject.project)
            .to eql project

          expect(subject.type)
            .to eql feature_type

          expect(subject.category)
            .to be_nil

          expect(subject.priority)
            .to eql high_priority
        end
      end

      context "for a wp overriding attributes with spaces between attribute and separator" do
        include_context "with a new work package with attributes with additional spaces"
        let(:submit_options) { { allow_override: "type,category,priority" } }

        it_behaves_like "work package created"

        it "sets the provided attributes" do
          expect(subject.project)
            .to eql project

          expect(subject.type)
            .to eql feature_type

          expect(subject.category)
            .to eql stock_category

          expect(subject.priority)
            .to eql urgent_priority
        end
      end

      context "for a wp overriding attributes in japanese" do
        include_context "with a new work package with attributes in japanese"
        let(:submit_options) { { issue: { project: "onlinestore" }, allow_override: "type" } }

        it_behaves_like "work package created"

        it "sets the provided attributes" do
          expect(subject.type)
            .to eql japanese_type
        end
      end

      context "for a wp with attachment" do
        include_context "with a new work package with attachment"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "adds the attachment" do
          expect(subject.attachments.count)
            .to be 1

          expect(subject.attachments.first.filename)
            .to eql "Paella.jpg"

          expect(subject.attachments.first.content_type)
            .to eql "image/jpeg"

          expect(subject.attachments.first.filesize)
            .to be 10790
        end
      end

      context "for a wp with attachment in apple format" do
        include_context "with a new work package with attachment in apple format"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "adds the attachment" do
          expect(subject.attachments.count)
            .to be 1

          expect(subject.attachments.first.filename)
            .to eql "paella.jpg"

          expect(subject.attachments.first.content_type)
            .to eql "image/jpeg"

          expect(subject.attachments.first.filesize)
            .to be 10790
        end
      end

      context "for a wp with a custom field value" do
        include_context "with a new work package with a custom field"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "sets the custom field value and removes it from the text" do
          expect(subject.custom_value_attributes)
            .to eql(custom_field.id => "Value for a custom field")

          expect(subject.description)
            .not_to include "searchable field"
        end
      end

      context "for a wp with invalid attributes" do
        include_context "with a new work package with invalid attributes"
        let(:submit_options) { { issue: { project: "onlinestore" }, allow_override: "type,category,priority" } }

        it_behaves_like "work package created"

        it "ignores the invalid attributes and set default ones where possible" do
          expect(subject.responsible)
            .to be_nil

          expect(subject.assigned_to)
            .to be_nil

          expect(subject.start_date)
            .to be_nil

          expect(subject.due_date)
            .to be_nil

          expect(subject.done_ratio)
            .to be_nil

          expect(subject.priority)
            .to eql priority_low
        end
      end

      context "for a wp with localized attributes" do
        include_context "with a new work package with localized attributes"
        let(:submit_options) { { allow_override: "type,category,priority" } }

        it_behaves_like "work package created"

        it "sets the provided attributes" do
          expect(subject.project)
            .to eql project

          expect(subject.type)
            .to eql feature_type

          expect(subject.category)
            .to eql stock_category

          expect(subject.priority)
            .to eql urgent_priority
        end
      end

      context "for a wp with iso 8859 1 subject" do
        include_context "with a new work package with iso 8859 1 subject"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "sets the subject" do
          expect(subject.subject)
            .to eql "Testmail from Webmail: ä ö ü..."
        end
      end

      context "for a wp with long subject" do
        include_context "with a new work package with long subject"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "sets the subject" do
          original_subject = <<~MSG.squish
            New ticket on a given project with a very long subject line
            which exceeds 255 chars and should not be ignored but chopped off.
            And if the subject line is still not long enough, we just add more text.
            And more text. Wow, this is really annoying. Especially, if you have nothing to say...
          MSG

          expect(subject.subject)
            .to eql original_subject[0, 255]
        end
      end

      context "for a wp with html only description" do
        include_context "with a new work package with html only description"
        let(:submit_options) { { issue: { project: "onlinestore" } } }

        it_behaves_like "work package created"

        it "sets the description" do
          expect(subject.description)
            .to eql "This is a html-only email."
        end
      end
    end

    context "when sending a reply to work package mail" do
      let!(:mail_user) { create(:admin, mail: "user@example.org") }
      let!(:work_package) { create(:work_package, project:) }

      before do
        # Avoid trying to extract text
        allow(OpenProject::Database).to receive(:allows_tsv?).and_return false
      end

      context "with attachments to be added" do
        it "updates a work package with attachment" do
          allow(WorkPackage).to receive(:find_by).with(id: 123).and_return(work_package)

          # Mail with two attachments, one of which is skipped by signature.asc filename match
          submit_email "update_ticket_with_attachment_and_sig.eml", issue: { project: "onlinestore" }

          work_package.reload

          # Expect comment
          expect(work_package.journals.last.notes).to eq "Reply to work package #123"
          expect(work_package.journals.last.user).to eq mail_user

          # Expect filename without signature to be saved
          expect(work_package.attachments.count).to eq(1)
          expect(work_package.attachments.first.filename).to eq("Photo25.jpg")
        end
      end

      context "with existing attachment" do
        let!(:attachment) { create(:attachment, container: work_package) }

        it "does not replace it (Regression #29722)" do
          work_package.reload
          allow(WorkPackage).to receive(:find_by).with(id: 123).and_return(work_package)

          # Mail with two attachments, one of which is skipped by signature.asc filename match
          submit_email "update_ticket_with_attachment_and_sig.eml", issue: { project: "onlinestore" }

          expect(work_package.attachments.length).to eq 2
        end
      end

      context "with reply text" do
        include_context "with a reply to a wp mention with quotes above"

        it_behaves_like "journal created"

        it "sends notifications" do
          assignee = create(:user,
                            member_with_permissions: { project => %i(view_work_packages) },
                            notification_settings: [build(:notification_setting, assignee: true, responsible: true)])

          responsible = create(:user,
                               member_with_permissions: { project => %i(view_work_packages) },
                               notification_settings: [build(:notification_setting, assignee: true, responsible: true)])
          work_package.update_column(:assigned_to_id, assignee.id)
          work_package.update_column(:responsible_id, responsible.id)

          # Sends notifications for the assignee and the author who is listening for all changes.
          expect do
            perform_enqueued_jobs do
              subject
            end
          end.to change(Notification, :count).by(2)
        end
      end

      context "when replying to mention mail with only text" do
        include_context "with a reply to a wp mention"

        it_behaves_like "journal created"

        it "adds the content to the last journal" do
          subject

          expect(work_package.journals.reload.last.notes)
            .to include "The text of the reply."
        end

        it "does not alter any attributes" do
          subject

          expect(work_package.journals.reload.last.details)
            .to be_empty
        end

        it "performs the changes in the name of the sender" do
          subject

          expect(work_package.journals.reload.last.user)
            .to eql user
        end
      end

      context "when replying to mention mail with text and attributes" do
        include_context "with a reply to a wp mention with attributes"

        it_behaves_like "journal created"

        it "adds the content to the last journal" do
          subject

          expect(work_package.journals.reload.last.notes)
            .to include "The text of the reply."
        end

        it "alters the attributes" do
          subject

          expect(work_package.journals.reload.last.details)
            .to eql(
              "due_date" => [nil, Date.parse("Fri, 31 Dec 2010")],
              "status_id" => [original_status.id, resolved_status.id],
              "responsible_id" => [nil, other_user.id],
              "assigned_to_id" => [nil, other_user.id],
              "start_date" => [nil, Date.parse("Fri, 01 Jan 2010")],
              "duration" => [nil, 365],
              "custom_fields_#{float_cf.id}" => [nil, "52.6"]
            )
        end

        it "performs the changes in the name of the sender" do
          subject

          expect(work_package.journals.reload.last.user)
            .to eql user
        end
      end

      context "with a custom field" do
        let(:work_package) { create(:work_package, project:) }
        let(:type) { create(:type) }

        before do
          type.custom_fields << custom_field
          type.save!

          allow(work_package).to receive(:available_custom_fields).and_return([custom_field])

          allow(WorkPackage).to receive(:find_by).with(id: 42).and_return(work_package)
          allow(User).to receive(:find_by_mail).with("h.wurst@openproject.com").and_return(mail_user)
        end

        context "as type text" do
          let(:custom_field) { create(:text_wp_custom_field, name: "Notes") }

          before do
            submit_email "wp_reply_with_text_custom_field.eml", issue: { project: project.identifier }

            work_package.reload
          end

          it "sets the value" do
            value = work_package.custom_values.where(custom_field_id: custom_field.id).pick(:value)

            expect(value).to eq "some text" # as given in .eml fixture
          end
        end

        context "as type list" do
          let(:custom_field) { create(:list_wp_custom_field, name: "Letters", possible_values: %w(A B C)) }

          before do
            submit_email "wp_reply_with_list_custom_field.eml", issue: { project: project.identifier }

            work_package.reload
          end

          it "sets the value" do
            option = CustomOption.where(custom_field_id: custom_field.id, value: "B").first # as given in .eml fixture
            value = work_package.custom_values.where(custom_field_id: custom_field.id).pick(:value)

            expect(value).to eq option.id.to_s
          end
        end
      end

      context "when receiving an auto reply" do
        include_context "with a reply to a wp mention with quotes above" do
          [
            "X-Auto-Response-Suppress: OOF",
            "Auto-Submitted: auto-replied",
            "Auto-Submitted: Auto-Replied",
            "Auto-Submitted: auto-generated"
          ].each do |header|
            subject do
              raw = File.read(File.join("#{File.dirname(__FILE__)}/../fixtures/mail_handler",
                                        "wp_reply_with_quoted_reply_above.eml"))
              raw = "#{header}\n#{raw}"

              described_class.receive(raw)
            end

            it "does not update the work package" do
              expect { subject }
                .not_to change(Journal, :count)
            end
          end
        end
      end
    end

    context "when sending a reply to a message mail" do
      include_context "with a reply to a message"

      it "creates a new message in the name of the sender", :aggregate_failures do
        expect(subject)
          .to be_a Message

        expect(subject.subject)
          .to eql("Response to the original message")

        expect(subject.content)
          .to include("Test message")

        expect(subject.author)
          .to eql user

        expect(subject.forum)
          .to eql message.forum

        expect(subject.parent)
          .to eql message
      end
    end

    describe "truncate emails based on the Setting" do
      context "with no setting", with_settings: { mail_handler_body_delimiters: "" } do
        include_context "for wp_on_given_project"

        it_behaves_like "work package created"

        it "adds the entire email into the work_package" do
          expect(subject.description)
            .to include("---")

          expect(subject.description)
            .to include("This paragraph is after the delimiter")
        end
      end

      context "with a single string", with_settings: { mail_handler_body_delimiters: "---" } do
        include_context "for wp_on_given_project"

        it_behaves_like "work package created"

        it "truncates the email at the delimiter for the work package" do
          expect(subject.description)
            .to include("This paragraph is before delimiters")

          expect(subject.description)
            .to include("--- This line starts with a delimiter")

          expect(subject.description)
            .not_to match(/^---$/)

          expect(subject.description)
            .not_to include("This paragraph is after the delimiter")
        end
      end

      context "with a single quoted reply (e.g. reply to a OpenProject email notification)",
              with_settings: { mail_handler_body_delimiters: "--- Reply above. Do not remove this line. ---" } do
        include_context "with a reply to a wp mention with quotes above"

        it_behaves_like "journal created"

        it "truncates the email at the delimiter with the quoted reply symbols (>)" do
          expect(subject.notes)
            .to include("An update to the issue by the sender.")

          expect(subject.notes)
            .not_to match(Regexp.escape("--- Reply above. Do not remove this line. ---"))

          expect(subject.notes)
            .not_to include("Looks like the JSON api for projects was missed.")
        end
      end

      context "with multiple strings",
              with_settings: { mail_handler_body_delimiters: "---\nBREAK" } do
        include_context "for wp_on_given_project"

        it_behaves_like "work package created"

        it "truncates the email at the first delimiter found (BREAK)" do
          expect(subject.description)
            .to include("This paragraph is before delimiters")

          expect(subject.description)
            .not_to include("BREAK")

          expect(subject.description)
            .not_to include("This paragraph is between delimiters")

          expect(subject.description)
            .not_to match(/^---$/)

          expect(subject.description)
            .not_to include("This paragraph is after the delimiter")
        end
      end
    end

    describe "category" do
      let!(:category) { create(:category, project:, name: "Foobar") }

      it "adds a work_package with category" do
        allow(Setting).to receive(:default_language).and_return("en")
        ProjectRole.non_member.update_attribute :permissions, [:add_work_packages]
        project.update_attribute :public, true

        work_package = submit_email "ticket_with_category.eml",
                                    issue: { project: "onlinestore" },
                                    allow_override: ["category"],
                                    unknown_user: "create"
        work_package_created(work_package)
        expect(work_package.category).to eq(category)
      end
    end
  end

  describe "#cleanup_body" do
    let(:input) do
      "Subject:foo\nDescription:bar\n" \
        ">>> myserver.example.org 2016-01-27 15:56 >>>\n... (Email-Body) ..."
    end
    let(:handler) { described_class.send :new }

    context "with regex delimiter" do
      before do
        allow(Setting).to receive(:mail_handler_body_delimiter_regex).and_return(">>>.+?>>>.*")
        allow(handler).to receive(:plain_text_body).and_return(input)
        allow(handler).to receive(:cleaned_up_text_body).and_call_original
      end

      it "removes the irrelevant lines" do
        expect(handler.send(:cleaned_up_text_body)).to eq("Subject:foo\nDescription:bar")
        expect(handler).to have_received(:cleaned_up_text_body)
      end
    end
  end

  private

  def read_email(filename)
    File.read(File.join("#{File.dirname(__FILE__)}/../fixtures/mail_handler", filename))
  end

  def submit_email(filename, options = {})
    MailHandler.receive(read_email(filename), options)
  end

  def work_package_created(work_package)
    expect(work_package).to be_a(WorkPackage)
    expect(work_package).not_to be_new_record
    work_package.reload
  end
end
