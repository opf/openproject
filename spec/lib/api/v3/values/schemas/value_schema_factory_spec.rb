# --copyright
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
# ++

require "spec_helper"

RSpec.describe API::V3::Values::Schemas::ValueSchemaFactory do
  include API::V3::Utilities::PathHelper

  describe ".for" do
    let!(:representer_instance) do
      instance_double(API::V3::Values::Schemas::PropertySchemaRepresenter)
    end
    let!(:representer_class) do
      allow(API::V3::Values::Schemas::PropertySchemaRepresenter)
        .to receive(:new)
              .and_return(representer_instance)
    end

    context "for the start_date property" do
      let(:property) { "start_date" }

      it "returns a schema representer" do
        expect(described_class.for(property))
          .to eq representer_instance
      end

      it "instantiates the representer with the proper params" do
        described_class.for(property)

        expect(API::V3::Values::Schemas::PropertySchemaRepresenter)
          .to have_received(:new)
                .with(API::V3::Values::Schemas::Model.new(I18n.t("attributes.start_date"), "Date"),
                      current_user: nil,
                      self_link: api_v3_paths.value_schema(property.camelcase(:lower)))
      end
    end

    context "for the due_date property" do
      let(:property) { "due_date" }

      it "returns a schema representer" do
        expect(described_class.for(property))
          .to eq representer_instance
      end

      it "instantiates the representer with the proper params" do
        described_class.for(property)

        expect(API::V3::Values::Schemas::PropertySchemaRepresenter)
          .to have_received(:new)
                .with(API::V3::Values::Schemas::Model.new(I18n.t("attributes.due_date"), "Date"),
                      current_user: nil,
                      self_link: api_v3_paths.value_schema(property.camelcase(:lower)))
      end
    end

    context "for the date property (for milestones)" do
      let(:property) { "date" }

      it "returns a schema representer" do
        expect(described_class.for(property))
          .to eq representer_instance
      end

      it "instantiates the representer with the proper params" do
        described_class.for(property)

        expect(API::V3::Values::Schemas::PropertySchemaRepresenter)
          .to have_received(:new)
                .with(API::V3::Values::Schemas::Model.new(I18n.t("attributes.date"), "Date"),
                      current_user: nil,
                      self_link: api_v3_paths.value_schema(property.camelcase(:lower)))
      end
    end

    context "for another property" do
      let(:property) { "bogus" }

      it "returns nil" do
        expect(described_class.for(property))
          .to be_nil
      end
    end
  end
end
