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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Names of API operations" do # rubocop:disable RSpec/DescribeClass
  let(:allowed_verbs) do
    %w[
      add
      cancel
      complete
      create
      delete
      download
      downvote
      end
      execute
      favorite
      get
      list
      lock
      move
      open
      prepare
      read
      remove
      star
      toggle
      unfavorite
      unlock
      unread
      unstar
      update
      upvote
      validate
    ]
  end

  Dir[
    Rails.root.join("docs/api/apiv3/paths/*.yml").to_s
  ].each do |f|
    name = File.basename(f)
    yaml = YAML.load_file(f)
    yaml.each do |http_method, method_doc|
      it "verb of #{name} (#{http_method.upcase})" do
        operation_id = method_doc["operationId"]
        verb = operation_id.split("_").first

        # TODO: technically the matching should be inverted (verb is "actual", "allowed_verbs" is expected),
        # but there is no proper DSL for this
        expect(allowed_verbs).to include(verb)
      end

      it "casing of #{name} (#{http_method.upcase})" do
        operation_id = method_doc["operationId"]
        expect(operation_id).to eq(operation_id.downcase)
      end
    end
  end
end
