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

require_relative "../../../spec_helper"

RSpec.describe Widget::Filters::WorkPackage do
  let(:admin) { create(:admin) }
  let(:work_package) { create(:work_package, project:) }

  let(:filter) do
    CostQuery::Filter::WorkPackageId.new.tap { |f| f.values = [work_package.id.to_s] }
  end
  let(:widget) { described_class.new(filter) }

  before { login_as(admin) }

  subject(:payload) { widget.send(:map_filter_values).first }

  describe "#map_filter_values" do
    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      let(:project) { create(:project) }

      it "emits the keys the opce-autocompleter template reads, with a hash-prefixed id" do
        expect(payload).to include(
          id: work_package.id,
          displayId: work_package.id.to_s,
          formattedId: "##{work_package.id}",
          subject: work_package.subject,
          name: work_package.subject
        )
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "MYPROJ") }

      it "emits the semantic identifier without a hash prefix" do
        expect(payload).to include(
          id: work_package.id,
          displayId: "MYPROJ-1",
          formattedId: "MYPROJ-1",
          subject: work_package.subject,
          name: work_package.subject
        )
      end
    end
  end
end
