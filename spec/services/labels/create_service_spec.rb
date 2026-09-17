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
require "services/base_services/behaves_like_create_service"

RSpec.describe Labels::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:call_attributes) { { name: "Some name" } }

    context "with a real service call" do
      let(:stub_model_instance) { false }
      let(:user) { create(:admin) }
      let(:call_attributes) { { name: "Bug" } }

      it "creates the label, setting the author to the calling user" do
        expect(subject).to be_success

        label = subject.result
        expect(label).to be_persisted
        expect(label.author).to eq(user)
        expect(label.name).to eq("Bug")
      end

      it "fails when the name is already taken, case-insensitively" do
        create(:label, name: "Bug")

        result = described_class.new(user:).call(name: "BUG")

        expect(result).to be_failure
        expect(result.errors.symbols_for(:name)).to include(:taken)
      end

      it "fails when the name is already taken but for surrounding whitespace" do
        create(:label, name: "Machine Learning")

        result = described_class.new(user:).call(name: "  Machine Learning  ")

        expect(result).to be_failure
        expect(result.errors.symbols_for(:name)).to include(:taken)
      end

      context "with a user lacking edit_work_packages in any project" do
        let(:user) { create(:user) }

        it "is unauthorized" do
          expect(subject).to be_failure
          expect(subject.errors.symbols_for(:base)).to include(:error_unauthorized)
        end
      end

      context "with a member holding edit_work_packages in a project" do
        let(:project) { create(:project) }
        let(:user) { create(:user, member_with_permissions: { project => %i[edit_work_packages] }) }

        it "creates the label, setting the author to the calling user" do
          expect(subject).to be_success

          label = subject.result
          expect(label).to be_persisted
          expect(label.author).to eq(user)
        end
      end
    end
  end
end
