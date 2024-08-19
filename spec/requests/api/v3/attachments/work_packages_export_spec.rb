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
require_relative "attachment_resource_shared_examples"

RSpec.describe "#{WorkPackages::Export} attachments" do
  it_behaves_like "an APIv3 attachment resource", include_by_container: false do
    let(:attachment_type) { :export }

    let(:create_permission) { :export_work_packages }
    let(:read_permission) { :export_work_packages }
    let(:update_permission) { :export_work_packages }

    let(:export) { create(:work_packages_export) }

    let(:missing_permissions_user) { create(:user) }
    let(:other_user) { create(:user) }

    let(:other_user_attachment) { create(:attachment, container: export, author: other_user) }

    describe "#get" do
      subject(:response) { last_response }

      let(:get_path) { api_v3_paths.attachment attachment.id }

      before do
        get get_path
      end

      context "for a user different from the author" do
        let(:attachment) { other_user_attachment }

        it "responds with 404" do
          expect(subject.status).to eq(404)
        end
      end
    end

    describe "#delete" do
      let(:path) { api_v3_paths.attachment attachment.id }

      before do
        delete path
      end

      context "for a user different from the author" do
        let(:attachment) { other_user_attachment }

        subject(:response) { last_response }

        it "responds with 404" do
          expect(subject.status).to eq 404
        end

        it "does not delete the attachment" do
          expect(Attachment.exists?(attachment.id)).to be_truthy
        end
      end
    end

    describe "#content" do
      let(:path) { api_v3_paths.attachment_content attachment.id }

      before do
        get path
      end

      subject(:response) { last_response }

      context "for a user different from the author" do
        let(:attachment) { other_user_attachment }

        it "responds with 404" do
          expect(subject.status).to eq 404
        end
      end
    end
  end
end
