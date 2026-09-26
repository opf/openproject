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

RSpec.describe API::V3::WorkPackages::WorkPackageEagerLoadingWrapper do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package1) { create(:work_package) }
  shared_let(:work_package2) { create(:work_package) }

  let(:extensions) { {} }

  before do
    allow(described_class).to receive(:eager_loading_extensions).and_return(extensions)
  end

  describe ".add_eager_loading_extension" do
    it "applies the extension to the collection query" do
      described_class.add_eager_loading_extension(:answer) do |eager_scope, _scope, _current_user|
        eager_scope.select("42 AS answer")
      end

      wrapped = described_class.wrap([work_package1.id, work_package2.id], user)

      expect(wrapped.pluck(:answer)).to eq([42, 42])
    end

    it "passes the unextended work package scope and the current user" do
      received = nil
      described_class.add_eager_loading_extension(:spy) do |eager_scope, scope, current_user|
        received = { ids: scope.pluck(:id), current_user: }
        eager_scope
      end

      described_class.wrap([work_package1.id], user)

      expect(received).to eq(ids: [work_package1.id], current_user: user)
    end

    it "replaces an extension registered under the same name" do
      described_class.add_eager_loading_extension(:answer) { |eager_scope, *| eager_scope.select("1 AS answer") }
      described_class.add_eager_loading_extension(:answer) { |eager_scope, *| eager_scope.select("2 AS answer") }

      wrapped = described_class.wrap([work_package1.id], user)

      expect(wrapped.first[:answer]).to eq(2)
    end
  end
end
