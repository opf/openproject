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

RSpec.describe API::V3::Notifications::NotificationCreatedRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:project) { build_stubbed(:project) }
  let(:document) { build_stubbed(:document, project:, title: "Meeting minutes") }
  let(:recipient) { build_stubbed(:user, firstname: "Jane", lastname: "Doe") }
  let(:actor) { build_stubbed(:user) }
  let(:notification) do
    build_stubbed(:notification,
                  recipient:,
                  resource: document,
                  actor:,
                  journal: nil,
                  reason: :mentioned,
                  read_ian: false)
  end
  let(:representer) do
    described_class.create notification,
                           current_user: actor,
                           embed_links:
  end

  let(:embed_links) { false }

  it "renders only the type, the id and the resource and recipient links" do
    expect(JSON.parse(generated))
      .to eq("_type" => "Notification",
             "id" => notification.id,
             "_links" => {
               "resource" => { "href" => api_v3_paths.document(document.id), "title" => "Meeting minutes" },
               "recipient" => { "href" => api_v3_paths.user(recipient.id), "title" => recipient.name }
             })
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Notification" }
    end

    it_behaves_like "property", :id do
      let(:value) { notification.id }
    end

    it "has no further properties of the full notification representation" do
      expect(generated).not_to have_json_path("readIAN")
      expect(generated).not_to have_json_path("reason")
      expect(generated).not_to have_json_path("createdAt")
      expect(generated).not_to have_json_path("updatedAt")
    end
  end

  describe "_links" do
    describe "resource" do
      it_behaves_like "has a titled link" do
        let(:link) { "resource" }
        let(:href) { api_v3_paths.document(document.id) }
        let(:title) { document.title }
      end
    end

    describe "recipient" do
      it_behaves_like "has a titled link" do
        let(:link) { "recipient" }
        let(:href) { api_v3_paths.user(recipient.id) }
        let(:title) { recipient.name }
      end
    end

    %w[self readIAN unreadIAN actor activity project].each do |name|
      describe name do
        it_behaves_like "has no link" do
          let(:link) { name }
        end
      end
    end
  end

  describe "_embedded" do
    it "embeds nothing" do
      expect(generated).not_to have_json_path("_embedded")
    end
  end
end
