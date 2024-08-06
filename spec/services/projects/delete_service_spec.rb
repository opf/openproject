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

RSpec.describe Projects::DeleteService, type: :model do
  shared_let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:instance) { described_class.new(user:, model: project) }

  subject { instance.call }

  context "if authorized" do
    context "when destroy succeeds" do
      it "destroys the projects" do
        without_partial_double_verification do
          allow(project).to receive(:archive)
          allow(Projects::DeleteProjectJob).to receive(:new)

          expect { subject }.to change(Project, :count).by(-1)
          expect(project).not_to have_received(:archive)
          expect(Projects::DeleteProjectJob)
            .not_to have_received(:new)
        end
      end

      context "when the file storages are involved", :webmock do
        it "removes any remote storages defined for the project" do
          storage = create(:nextcloud_storage)
          project_storage = create(:project_storage, project:, storage:)
          work_package = create(:work_package, project:)
          create(:file_link, container: work_package, storage:)
          delete_folder_url =
            "#{storage.host}/remote.php/dav/files/#{storage.username}/#{project_storage.managed_project_folder_path.chop}/"

          stub_request(:delete, delete_folder_url).to_return(status: 204, body: nil, headers: {})

          expect { subject }.to change(Storages::ProjectStorage, :count).by(-1)
        end
      end

      it "sends a success mail" do
        expect(subject).to be_success
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.subject).to eq(I18n.t("projects.delete.completed", name: project.name))
          text_part = mail.text_part.to_s
          html_part = mail.html_part.to_s

          expect(text_part).to include(project.name)
          expect(html_part).to include(project.name)
        end
      end

      context "with a hierarchy of projects" do
        let!(:children) { create_list(:project, 2, parent: project) }
        let!(:grand_children) { create_list(:project, 2, parent: children.first) }
        let(:all_children) { children + grand_children }

        before do
          project.reload
        end

        it "destroys the projects" do
          expect { subject }.to change(Project, :count).by(-5)
        end

        it "sends a success mail mentioning all the child projects" do
          expect { subject }.to change(ActionMailer::Base.deliveries, :size).by(1)

          ActionMailer::Base.deliveries.last.tap do |mail|
            expect(mail.subject).to eq(I18n.t("projects.delete.completed", name: project.name))
            text_part = mail.text_part.to_s
            html_part = mail.html_part.to_s

            all_children.each do |child|
              expect(text_part).to include(child.name)
              expect(html_part).to include(child.name)
            end
          end
        end
      end
    end

    it "sends a message on destroy failure" do
      expect(project).to receive(:destroy).and_return false

      expect(ProjectMailer)
        .to receive_message_chain(:delete_project_failed, :deliver_now)

      expect(Projects::DeleteProjectJob)
        .not_to receive(:new)

      expect(subject).to be_failure
    end
  end

  context "if not authorized" do
    let(:user) { build_stubbed(:user) }

    it "returns an error" do
      allow(Projects::DeleteProjectJob).to receive(:new)

      expect(subject).to be_failure
      expect(Projects::DeleteProjectJob).not_to have_received(:new)
    end
  end

  context "with the seeded demo project" do
    let(:demo_project) { create(:project, name: "Demo project", identifier: "demo-project", public: true) }
    let(:instance) { described_class.new(user:, model: demo_project) }

    it "saves in a Setting that the demo project was deleted (regression #52826)" do
      # Delete the demo project
      expect(subject).to be_success
      expect(demo_project.destroyed?).to be(true)

      # Demo project is not available for the onboarding tour any more
      expect(Setting.demo_projects_available).to be(false)
    end
  end
end
