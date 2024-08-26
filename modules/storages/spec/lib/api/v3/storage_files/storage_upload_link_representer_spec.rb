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
require_module_spec_helper

RSpec.describe API::V3::StorageFiles::StorageUploadLinkRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:user) { build_stubbed(:user) }
  let(:token) { "xyz123" }
  let(:destination) { "https://example.com/upload/#{token}" }
  let(:upload_link) do
    Storages::UploadLink.new("https://example.com/upload/#{token}", :post)
  end
  let(:representer) { described_class.new(upload_link, current_user: user) }

  subject { representer.to_json }

  describe "links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }

    describe "to self" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { "#{API::V3::URN_PREFIX}storages:upload_link:no_link_provided" }
      end
    end

    describe "without finalize link" do
      describe "to destination" do
        it_behaves_like "has a titled link" do
          let(:link) { "destination" }
          let(:href) { destination }
          let(:title) { "Upload File" }
        end
      end

      describe "not to finalize" do
        it_behaves_like "has no link" do
          let(:link) { "finalize" }
        end
      end
    end
  end
end
