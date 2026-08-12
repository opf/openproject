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

RSpec.describe Exports::PDF::Common::Markdown::MD2PDFExport do
  let(:exporter) { described_class.allocate }
  let(:type) { build_stubbed(:type, name: "Bug") }
  let(:status) { build_stubbed(:status, name: "In Progress") }
  let(:work_package) do
    build_stubbed(:work_package, type:, status:, subject: "Fix login")
  end

  describe "#wp_mention_macro" do
    let(:admin) { create(:admin) }
    let(:wp) { create(:work_package) }

    before do
      User.current = admin
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "generates a link URL with the numeric id" do
        result = exporter.wp_mention_macro("##{wp.id}", wp.id.to_s, {})
        expect(result.first[:link]).to include(wp.id.to_s)
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      it "generates a link URL with the semantic identifier" do
        result = exporter.wp_mention_macro("##{wp.id}", wp.id.to_s, {})
        expect(result.first[:link]).to include(wp.identifier)
      end
    end
  end

  describe "#expand_wp_mention" do
    context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "returns formatted_id for level 1" do
        expect(exporter.expand_wp_mention(work_package, "##{work_package.id}"))
          .to eq("##{work_package.id}")
      end

      it "uses formatted_id in level 2 expansion" do
        result = exporter.expand_wp_mention(work_package, "###{work_package.id}")
        expect(result).to eq("Bug ##{work_package.id}: Fix login")
      end

      it "uses formatted_id in level 3 expansion" do
        allow(exporter).to receive(:work_package_dates).with(work_package).and_return("")
        result = exporter.expand_wp_mention(work_package, "####{work_package.id}")
        expect(result).to eq("In Progress Bug ##{work_package.id}: Fix login")
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.identifier = "PROJ-42" }

      it "returns semantic formatted_id for level 1" do
        expect(exporter.expand_wp_mention(work_package, "##{work_package.id}"))
          .to eq("PROJ-42")
      end

      it "uses semantic formatted_id in level 2 expansion" do
        result = exporter.expand_wp_mention(work_package, "###{work_package.id}")
        expect(result).to eq("Bug PROJ-42: Fix login")
      end

      it "uses semantic formatted_id in level 3 expansion" do
        allow(exporter).to receive(:work_package_dates).with(work_package).and_return("")
        result = exporter.expand_wp_mention(work_package, "####{work_package.id}")
        expect(result).to eq("In Progress Bug PROJ-42: Fix login")
      end
    end
  end
end
