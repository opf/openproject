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

RSpec.describe OpenProject::ChangedBySystem do
  subject(:model) do
    model = News.new
    model.extend(described_class)
    model
  end

  describe "#changed_by_user" do
    context "when an attribute is changed" do
      before do
        model.title = "abc"
      end

      it "returns the attribute" do
        expect(model.changed_by_user)
          .to contain_exactly("title")
      end
    end

    context "when an attribute is changed by the system" do
      before do
        model.change_by_system do
          model.title = "abc"
        end
      end

      it "returns no attributes" do
        expect(model.changed_by_user)
          .to be_empty
      end
    end

    context "when an attribute is changed by the system first and then by the user to a different value" do
      before do
        model.change_by_system do
          model.title = "abc"
        end

        model.title = "xyz"
      end

      it "returns the attribute" do
        expect(model.changed_by_user)
          .to contain_exactly("title")
      end
    end

    context "when an attribute is changed by the system first and then by the user to the same value" do
      before do
        model.change_by_system do
          model.title = "abc"
        end

        model.title = "abc"
      end

      it "returns no attribute" do
        expect(model.changed_by_user)
          .to be_empty
      end
    end

    context "when the model has the acts_as_customizable plugin included" do
      subject(:model) do
        create(:work_package, project:).tap do |wp|
          wp.extend(described_class)
        end
      end

      let(:type) { create(:type_standard) }
      let(:project) { create(:project, types: [type]) }
      let(:cf1) { create(:work_package_custom_field) }

      before do
        project.work_package_custom_fields << cf1
        type.custom_fields << cf1
      end

      it "returns the custom fields too" do
        model.custom_field_values = { cf1.id => "test" }
        expect(model.changed_by_user)
          .to include(cf1.attribute_name)
      end
    end
  end
end
