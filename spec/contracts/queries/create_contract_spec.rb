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
require_relative "shared_contract_examples"

RSpec.describe Queries::CreateContract do
  include_context "with queries contract"

  describe "include subprojects" do
    let(:query) do
      Query.new name: "foo",
                include_subprojects:,
                project:
    end

    context "when true" do
      let(:include_subprojects) { true }

      it_behaves_like "contract is valid"
    end

    context "when false" do
      let(:include_subprojects) { false }

      it_behaves_like "contract is valid"
    end

    context "when nil" do
      let(:include_subprojects) { nil }

      it_behaves_like "contract is invalid", include_subprojects: %i[inclusion]
    end
  end
end
