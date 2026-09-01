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

RSpec.describe Queries::Documents::Filters::ProjectFilter do
  include_context "with visible projects"

  let(:model) { Document }

  describe "#values=" do
    let(:instance) { described_class.create!(name: :project_id, operator: "=", values:) }

    context "with a project identifier" do
      let(:values) { [project1.identifier] }

      it "replaces the identifier with the project id" do
        expect(instance.values).to eq([project1.id.to_s])
        expect(instance).to be_valid
      end
    end

    context "with a semantic project identifier", with_settings: { work_packages_identifier: "semantic" } do
      let(:project1) { create(:project, identifier: "SDT") }
      let(:values) { %w[SDT] }

      it "replaces the identifier with the project id" do
        expect(instance.values).to eq([project1.id.to_s])
        expect(instance).to be_valid
      end
    end

    context "with a project identifier in a different case" do
      let(:values) { [project1.identifier.upcase] }

      it "replaces the identifier with the project id" do
        expect(instance.values).to eq([project1.id.to_s])
      end
    end

    context "with a project id" do
      let(:values) { [project1.id.to_s] }

      it "keeps the id" do
        expect(instance.values).to eq([project1.id.to_s])
      end
    end

    context "with the identifier of one and the id of another project" do
      let(:values) { [project1.identifier, project2.id.to_s] }

      it "replaces only the identifier" do
        expect(instance.values).to eq([project1.id.to_s, project2.id.to_s])
      end
    end

    context "with the identifier of a project the user cannot see" do
      let(:invisible_project) { create(:project) }
      let(:values) { [invisible_project.identifier] }

      it "keeps the identifier and is invalid" do
        expect(instance.values).to eq([invisible_project.identifier])
        expect(instance).not_to be_valid
      end
    end
  end

  it_behaves_like "project_id list_optional filter"
end
