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

RSpec.describe API::V3::Posts::PostRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:message) do
    build_stubbed(:message) do |wp|
      allow(wp)
        .to receive(:project)
        .and_return(project)
    end
  end
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(message, current_user: user, embed_links: true)
  end
  let(:permissions) { all_permissions }
  let(:all_permissions) { %i(edit_messages) }

  subject { representer.to_json }

  describe "_links" do
    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.post message.id }
    end

    it_behaves_like "has an untitled link" do
      let(:link) { :attachments }
      let(:href) { api_v3_paths.attachments_by_post message.id }
    end

    it_behaves_like "has a titled link" do
      let(:link) { :project }
      let(:title) { project.name }
      let(:href) { api_v3_paths.project project.id }
    end

    it_behaves_like "has an untitled action link" do
      let(:link) { :addAttachment }
      let(:href) { api_v3_paths.attachments_by_post message.id }
      let(:method) { :post }
      let(:permission) { :edit_messages }
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "Post" }
    end

    it_behaves_like "property", :id do
      let(:value) { message.id }
    end

    it_behaves_like "property", :subject do
      let(:value) { message.subject }
    end
  end

  describe "_embedded" do
    it "has project embedded" do
      expect(subject)
        .to be_json_eql(project.name.to_json)
        .at_path("_embedded/project/name")
    end
  end
end
