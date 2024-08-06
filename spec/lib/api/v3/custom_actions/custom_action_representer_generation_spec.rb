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

RSpec.describe API::V3::CustomActions::CustomActionRepresenter do
  include API::V3::Utilities::PathHelper

  let(:custom_action) { build_stubbed(:custom_action) }
  let(:user) { build_stubbed(:user) }

  let(:representer) do
    described_class.new(custom_action, current_user: user, embed_links: true)
  end

  subject { representer.to_json }

  context "properties" do
    it "has a _type property" do
      expect(subject)
        .to be_json_eql("CustomAction".to_json)
        .at_path("_type")
    end

    it "has a name property" do
      expect(subject)
        .to be_json_eql(custom_action.name.to_json)
        .at_path("name")
    end

    it "has a description property" do
      expect(subject)
        .to be_json_eql(custom_action.description.to_json)
        .at_path("description")
    end
  end

  context "links" do
    it_behaves_like "has a titled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.custom_action(custom_action.id) }
      let(:title) { custom_action.name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "executeImmediately" }
      let(:href) { api_v3_paths.custom_action_execute(custom_action.id) }
      let(:title) { "Execute #{custom_action.name}" }
      let(:method) { "post" }
    end
  end
end
