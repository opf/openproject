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

RSpec.describe Workflow do
  describe ".copy" do
    shared_let(:status0) { create(:status) }
    shared_let(:status1) { create(:status) }
    shared_let(:role) { create(:project_role) }
    shared_let(:type) { create(:type) }
    shared_let(:role_target) { create(:project_role) }
    shared_let(:type_target) { create(:type) }
    shared_let(:role_target2) { create(:project_role) }
    shared_let(:type_target2) { create(:type) }

    shared_examples_for "copied workflow" do
      let(:expected_type) { type_target }
      let(:expected_role) { role_target }

      it { expect(subject.old_status).to eq(workflow_src.old_status) }

      it { expect(subject.new_status).to eq(workflow_src.new_status) }

      it { expect(subject.type).to eq(expected_type) }

      it { expect(subject.role).to eq(expected_role) }

      it { expect(subject.author).to eq(workflow_src.author) }

      it { expect(subject.assignee).to eq(workflow_src.assignee) }
    end

    context "for a workflow w/o author or assignee" do
      let!(:workflow_src) do
        create(:workflow,
               old_status: status0,
               new_status: status1,
               type_id: type.id,
               role:)
      end

      before { described_class.copy(type, role, type_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with author" do
      let!(:workflow_src) do
        create(:workflow,
               old_status: status0,
               new_status: status1,
               type_id: type.id,
               role:,
               author: true)
      end

      before { described_class.copy(type, role, type_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with assignee" do
      let!(:workflow_src) do
        create(:workflow,
               old_status: status0,
               new_status: status1,
               type_id: type.id,
               role:,
               assignee: true)
      end

      before { described_class.copy(type, role, type_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "when copying to multiple types and roles" do
      let!(:workflow_src) do
        create(:workflow,
               old_status: status0,
               new_status: status1,
               type_id: type.id,
               role:)
      end

      before { described_class.copy(type, role, [type_target, type_target2], [role_target, role_target2]) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("type_id DESC, role_id DESC")).first }

        let(:expected_role) { role_target2 }
        let(:expected_type) { type_target2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("type_id DESC, role_id DESC")).second }

        let(:expected_role) { role_target }
        let(:expected_type) { type_target2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("type_id DESC, role_id DESC")).third }

        let(:expected_role) { role_target2 }
        let(:expected_type) { type_target }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("type_id DESC, role_id DESC")).fourth }

        let(:expected_role) { role_target }
        let(:expected_type) { type_target }
      end
    end
  end
end
