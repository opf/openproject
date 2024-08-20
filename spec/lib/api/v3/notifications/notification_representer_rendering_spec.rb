#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe API::V3::Notifications::NotificationRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  shared_let(:project) { create(:project) }
  let(:resource) { build_stubbed(:work_package, project:) }

  let(:recipient) { build_stubbed(:user) }
  let(:journal) { nil }
  let(:actor) { nil }
  let(:reason) { :mentioned }
  let(:notification) do
    build_stubbed(:notification,
                  recipient:,
                  resource:,
                  journal:,
                  actor:,
                  reason:,
                  read_ian:)
  end
  let(:representer) do
    described_class.create notification,
                           current_user: recipient,
                           embed_links:
  end

  let(:embed_links) { false }
  let(:read_ian) { false }

  describe "self link" do
    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.notification notification.id }
    end
  end

  describe "IAN read and unread links" do
    context "when unread" do
      it_behaves_like "has an untitled link" do
        let(:link) { "readIAN" }
        let(:href) { api_v3_paths.notification_read_ian notification.id }
        let(:method) { :post }
      end

      it_behaves_like "has no link" do
        let(:link) { "unreadIAN" }
      end
    end

    context "when read" do
      let(:read_ian) { true }

      it_behaves_like "has an untitled link" do
        let(:link) { "unreadIAN" }
        let(:href) { api_v3_paths.notification_unread_ian notification.id }
        let(:method) { :post }
      end

      it_behaves_like "has no link" do
        let(:link) { "readIAN" }
      end
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Notification" }
    end

    it_behaves_like "property", :id do
      let(:value) { notification.id }
    end

    describe "reason" do
      (Notification::REASONS.keys - %i[date_alert_start_date date_alert_due_date]).each do |notification_reason|
        context "for a #{notification_reason} reason" do
          let(:reason) { notification_reason }

          it_behaves_like "property", :reason do
            let(:value) { notification_reason }
          end
        end
      end

      %i[date_alert_start_date date_alert_due_date].each do |notification_reason|
        context "for a #{notification_reason} reason" do
          let(:reason) { notification_reason }

          it_behaves_like "property", :reason do
            let(:value) { "dateAlert" }
          end
        end
      end
    end

    it_behaves_like "datetime property", :createdAt do
      let(:value) { notification.created_at }
    end

    it_behaves_like "datetime property", :updatedAt do
      let(:value) { notification.updated_at }
    end

    it "is expected to not have a message" do
      expect(subject).not_to have_json_path("message")
    end
  end

  describe "project" do
    it_behaves_like "has a titled link" do
      let(:link) { "project" }
      let(:href) { api_v3_paths.project project.id }
      let(:title) { project.name }
    end

    context "when embedding is true" do
      let(:embed_links) { true }

      it "embeds the context" do
        expect(generated)
          .to be_json_eql("Project".to_json)
                .at_path("_embedded/project/_type")

        expect(generated)
          .to be_json_eql(project.name.to_json)
                .at_path("_embedded/project/name")
      end
    end
  end

  describe "resource polymorphic resource" do
    it_behaves_like "has a titled link" do
      let(:link) { "resource" }
      let(:title) { resource.subject }
      let(:href) { api_v3_paths.work_package resource.id }
    end

    context "when embedding is true" do
      let(:embed_links) { true }

      it "embeds the resource" do
        expect(generated)
          .to be_json_eql("WorkPackage".to_json)
                .at_path("_embedded/resource/_type")
      end
    end
  end

  describe "actor" do
    context "when not set" do
      it_behaves_like "has no link" do
        let(:link) { "actor" }
      end
    end

    context "when set" do
      let(:actor) { create(:user) }

      it_behaves_like "has a titled link" do
        let(:link) { "actor" }
        let(:href) { api_v3_paths.user actor.id }
        let(:title) { actor.name }
      end
    end
  end

  describe "journal" do
    context "when not set" do
      it_behaves_like "has no link" do
        let(:link) { "activity" }
      end
    end

    context "when set" do
      let(:journal) { build_stubbed(:work_package_journal) }

      it_behaves_like "has an untitled link" do
        let(:link) { "activity" }
        let(:href) { api_v3_paths.activity journal.id }
      end

      context "when embedding is true" do
        let(:embed_links) { true }

        it "embeds the resource" do
          expect(generated)
            .to be_json_eql("Activity".to_json)
                  .at_path("_embedded/activity/_type")
        end
      end
    end
  end

  describe "details" do
    shared_examples_for "embeds a Values::Property for startDate" do
      it "embeds a Values::Property" do
        expect(generated)
          .to be_json_eql("Values::Property".to_json)
                .at_path("_embedded/details/0/_type")
      end

      it "has a startDate value for the `property` property" do
        expect(generated)
          .to be_json_eql("startDate".to_json)
                .at_path("_embedded/details/0/property")
      end

      it "has a work_package`s start_date for the value" do
        expect(generated)
          .to be_json_eql(resource.start_date.to_json)
                .at_path("_embedded/details/0/value")
      end
    end

    context "for a dateAlert when embedding" do
      let(:reason) { :date_alert_start_date }
      let(:embed_links) { true }

      it_behaves_like "embeds a Values::Property for startDate"
    end

    context "for a dateAlert when not embedding" do
      let(:reason) { :date_alert_start_date }
      let(:embed_links) { false }

      it_behaves_like "embeds a Values::Property for startDate"
    end

    context "for a mention when embedding" do
      let(:reason) { :mentioned }
      let(:embed_links) { true }

      it "has an empty details array" do
        expect(generated)
          .to have_json_size(0)
                .at_path("_embedded/details")
      end
    end
  end
end
