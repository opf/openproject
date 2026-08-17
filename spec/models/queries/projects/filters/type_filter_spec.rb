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

RSpec.describe Queries::Projects::Filters::TypeFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :type_id }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :type_id }
    let(:values) { ["3"] }
  end

  def filter(operator, values)
    described_class.create!(operator:, values:)
  end

  describe "#allowed_values" do
    let!(:first) { create(:type, name: "Alpha") }
    let!(:second) { create(:type, name: "Beta") }

    it "is a list of the types in their configured order" do
      expect(filter("=", []).allowed_values)
        .to eq [["Alpha", first.id], ["Beta", second.id]]
    end
  end

  describe "#apply_to" do
    let(:bug) { create(:type) }
    let(:task) { create(:type) }
    let(:milestone) { create(:type) }

    let!(:bug_project) { create(:project, types: [bug]) }
    let!(:task_project) { create(:project, types: [task]) }
    let!(:both_project) { create(:project, types: [bug, task]) }
    let!(:milestone_project) { create(:project, types: [milestone]) }

    let(:values) { [bug.id.to_s, task.id.to_s] }

    context 'for "="' do
      it "returns every project having one of the types, without duplicating those having several" do
        expect(filter("=", values).apply_to(Project))
          .to contain_exactly(bug_project, task_project, both_project)
      end
    end

    context 'for "!"' do
      it "returns only the projects having none of the types" do
        expect(filter("!", values).apply_to(Project))
          .to contain_exactly(milestone_project)
      end
    end
  end
end
