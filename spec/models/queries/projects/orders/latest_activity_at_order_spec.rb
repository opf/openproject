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

RSpec.describe Queries::Projects::Orders::LatestActivityAtOrder do
  let(:instance) do
    described_class.new("").tap do |i|
      i.direction = direction
    end
  end

  shared_let(:recent_project) { create(:project, updated_at: 1.day.ago, created_at: 1.year.ago) }
  shared_let(:today_project) { create(:project, updated_at: 1.hour.ago, created_at: 1.year.ago) }
  shared_let(:inactive_project) { create(:project, updated_at: 1.year.ago, created_at: 1.year.ago) }

  describe "#apply_to" do
    context "when sorting asc" do
      let(:direction) { :asc }

      it "orders by the latest activity desc" do
        expect(instance.apply_to(Project).to_a)
          .to eql([inactive_project, recent_project, today_project])
      end
    end

    context "when sorting desc" do
      let(:direction) { :desc }

      it "orders by the latest activity desc" do
        expect(instance.apply_to(Project).to_a)
          .to eql([today_project, recent_project, inactive_project])
      end
    end

    context "with an invalid direction" do
      let(:direction) { "bogus" }

      it "raises an error" do
        expect { instance.apply_to(Project) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
