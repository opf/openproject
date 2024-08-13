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
require_relative "../shared_expectations"

RSpec.describe CustomActions::Actions::Priority do
  let(:key) { :priority }
  let(:type) { :associated_property }
  let(:allowed_values) do
    priorities = [build_stubbed(:issue_priority),
                  build_stubbed(:issue_priority)]
    allow(IssuePriority)
      .to receive_message_chain(:select, :order)
            .and_return(priorities)

    [{ value: priorities.first.id, label: priorities.first.name },
     { value: priorities.last.id, label: priorities.last.name }]
  end

  it_behaves_like "base custom action"
  it_behaves_like "associated custom action" do
    describe "#allowed_values" do
      it "is the list of all priorities" do
        allowed_values

        expect(instance.allowed_values)
          .to eql(allowed_values)
      end
    end
  end
end
