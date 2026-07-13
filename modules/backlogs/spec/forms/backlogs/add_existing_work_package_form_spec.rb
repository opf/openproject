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

RSpec.describe Backlogs::AddExistingWorkPackageForm, type: :forms do
  include_context "with rendered form"

  let(:project) { build_stubbed(:project, id: 99) }
  let(:form_arguments) { { url: "/foo" } }
  let(:params) { { project:, target_id: } }

  subject(:form) { page }

  describe "#autocompleter" do
    context "when target is a sprint" do
      let(:target_id) { "sprint:7" }

      it "filters for work packages with open status and not in target sprint" do
        expect(form).to have_element "opce-autocompleter" do |autocompleter|
          expect(autocompleter["data-filters"]).to be_json_eql <<-JSON
            [
              {"name": "status", "operator": "o"},
              {"name": "sprint", "operator": "!", "values": [7]}
            ]
          JSON
        end
      end
    end

    context "when target is a backlog bucket" do
      let(:target_id) { "backlog_bucket:3" }

      it "filters for work packages with open status and not in target backlog bucket" do
        expect(form).to have_element "opce-autocompleter" do |autocompleter|
          expect(autocompleter["data-filters"]).to be_json_eql <<-JSON
            [
              {"name": "status", "operator": "o"},
              {"name": "backlogBucket", "operator": "!", "values": [3]}
            ]
          JSON
        end
      end
    end

    context "when target is inbox" do
      let(:target_id) { "inbox" }

      it "filters for work packages with open status and not in inbox" do
        expect(form).to have_element "opce-autocompleter" do |autocompleter|
          expect(autocompleter["data-filters"]).to be_json_eql <<-JSON
            [
              {"name": "status", "operator": "o"},
              {"name": "backlogInbox", "operator": "=", "values": ["f"]}
            ]
          JSON
        end
      end
    end
  end
end
