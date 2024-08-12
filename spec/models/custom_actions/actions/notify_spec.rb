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

RSpec.describe CustomActions::Actions::Notify do
  let(:key) { :notify }
  let(:type) { :associated_property }
  let(:allowed_values) do
    users = [build_stubbed(:user),
             build_stubbed(:group)]

    allow(Principal)
      .to receive_message_chain(:not_locked, :select, :select_for_name, :ordered_by_name)
            .and_return(users)

    [{ value: nil, label: "-" },
     { value: users.first.id, label: users.first.name },
     { value: users.last.id, label: users.last.name }]
  end

  it_behaves_like "base custom action" do
    describe "#allowed_values" do
      it "is the list of all users" do
        allowed_values

        expect(instance.allowed_values)
          .to eql(allowed_values)
      end
    end

    it_behaves_like "associated custom action validations"

    describe "#apply" do
      let(:work_package) { build_stubbed(:work_package) }

      it "adds a note with all values distinguished by type" do
        principals = [build_stubbed(:user),
                      build_stubbed(:group),
                      build_stubbed(:user)]

        allow(Principal)
          .to receive_message_chain(:not_locked, :select, :select_for_name, :ordered_by_name, :where)
          .and_return(principals)

        instance.values = principals.map(&:id)

        expect(work_package)
          .to receive(:journal_notes=)
          .with("user##{principals[0].id}, group##{principals[1].id}, user##{principals[2].id}")

        instance.apply(work_package)
      end
    end

    describe "#multi_value?" do
      it "is true" do
        expect(instance)
          .to be_multi_value
      end
    end
  end
end
