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

RSpec.describe OpenProject::Acts::Watchable::RouteConstraint do
  let(:request) { instance_double(ActionDispatch::Request, path_parameters:) }
  let(:path_parameters) { { object_id: id, object_type: type } }

  describe "matches?" do
    %w[
      forums
      meetings
      messages
      news
      wiki_pages
      wikis
      work_packages
    ].each do |type|
      describe "routing #{type} watches" do
        let(:type) { type }

        describe "for a valid id string" do
          let(:id) { "1" }

          it "is true" do
            expect(described_class).to be_matches(request)
          end
        end

        describe "for an invalid id string" do
          let(:id) { "schmu" }

          it "is false" do
            expect(described_class).not_to be_matches(request)
          end
        end
      end
    end

    describe "for a non watched model" do
      let(:type) { "schmu" }
      let(:id) { "4" }

      it "is false" do
        expect(described_class).not_to be_matches(request)
      end
    end
  end
end
