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

module RSpecOpExt
  module ForEachContext
    # Runs the same example group multiple times: once for each given named
    # context.
    #
    # For each named context, the context is applied and the tests are run. It
    # allows to have multiple shared contexts and only one example group,
    # instead of having shared examples and multiple contexts including the
    # shared examples. It generally reads better.
    #
    # @example
    #
    #     RSpec.describe "something" do
    #       shared_context "early in the morning" do
    #         let(:time) { "06:30" }
    #       end
    #
    #       shared_context "late in the evening" do
    #         let(:time) { "23:00" }
    #       end
    #
    #       for_each_context "early in the morning",
    #                        "late in the evening" do
    #         it "has energy" do
    #           expect(body.energy_level).to eq(100)
    #         end
    #       end
    #     end
    def for_each_context(*context_names, &blk)
      context_names.each do |context_name|
        context context_name do
          include_context context_name

          instance_exec(&blk)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.extend RSpecOpExt::ForEachContext
end
