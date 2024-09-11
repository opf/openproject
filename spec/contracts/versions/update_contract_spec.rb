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
require_relative "shared_contract_examples"

RSpec.describe Versions::UpdateContract do
  it_behaves_like "version contract" do
    let(:version) do
      build_stubbed(:version,
                    project: version_project,
                    description: version_description,
                    start_date: version_start_date,
                    effective_date: version_due_date,
                    status: version_status,
                    sharing: version_sharing,
                    wiki_page_title: version_wiki_page_title).tap do |v|
        # in order to actually have something changed
        v.name = version_name
      end
    end

    subject(:contract) { described_class.new(version, current_user) }

    describe "assignable_values" do
      context "for project" do
        it "is empty" do
          expect(subject.assignable_values(:project, current_user))
            .to be_empty
        end
      end

      context "for status" do
        it "is a list of all available status" do
          expect(subject.assignable_values(:status, current_user))
            .to eql %w(open locked closed)
        end
      end

      context "for sharing" do
        it "is a list of values" do
          expect(subject.assignable_values(:sharing, current_user))
            .to match_array %w(none descendants hierarchy tree)
        end

        context "if the user is admin" do
          let(:current_user) { build_stubbed(:admin) }

          it "is a list of values" do
            expect(subject.assignable_values(:sharing, current_user))
              .to match_array %w(none descendants system hierarchy tree)
          end
        end
      end

      context "for something else" do
        it "is nil" do
          expect(subject.assignable_values(:start_date, current_user))
            .to be_nil
        end
      end
    end
  end
end
