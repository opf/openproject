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

RSpec.shared_examples "updates the news" do
  context "with an empty title" do
    let(:parameters) do
      { title: "" }
    end

    it "returns an error" do
      expect(last_response.status).to eq(422)
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
              .at_path("errorIdentifier")

      expect(parsed_response["_embedded"]["details"]["attribute"])
        .to eq "title"

      expect(parsed_response["message"])
        .to eq "Title can't be blank."
    end
  end

  context "with a new title" do
    let(:parameters) do
      { title: "my new title" }
    end

    it "updates the news" do
      expect(last_response.status).to eq(200)

      news.reload

      expect(news.title).to eq "my new title"
    end
  end
end
