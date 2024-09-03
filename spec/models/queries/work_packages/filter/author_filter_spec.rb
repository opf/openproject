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

RSpec.describe Queries::WorkPackages::Filter::AuthorFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :author_id }

    let(:user_1) { build_stubbed(:user) }

    let(:principal_loader) do
      loader = double("principal_loader")
      allow(loader)
        .to receive(:user_values)
        .and_return([])

      loader
    end

    before do
      allow(Queries::WorkPackages::Filter::PrincipalLoader)
        .to receive(:new)
        .with(project)
        .and_return(principal_loader)
    end

    describe "#available?" do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
          .and_return(logged_in)
      end

      context "when being logged in" do
        it "is true if no other user is available" do
          expect(instance).to be_available
        end

        it "is true if there is another user selectable" do
          allow(principal_loader)
            .to receive(:user_values)
            .and_return([[nil, user_1.id.to_s]])

          expect(instance).to be_available
        end
      end

      context "when not being logged in" do
        let(:logged_in) { false }

        it "is false if no other user is available" do
          expect(instance).not_to be_available
        end

        it "is true if there is another user selectable" do
          allow(principal_loader)
            .to receive(:user_values)
            .and_return([[nil, user_1.id.to_s]])

          expect(instance).to be_available
        end
      end
    end

    describe "#allowed_values" do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
          .and_return(logged_in)
      end

      context "when being logged in" do
        it "returns the me value and the available users" do
          allow(principal_loader)
            .to receive(:user_values)
            .and_return([[nil, user_1.id.to_s]])

          expect(instance.allowed_values)
            .to contain_exactly([I18n.t(:label_me), "me"], [nil, user_1.id.to_s])
        end
      end

      context "when not being logged in" do
        let(:logged_in) { false }

        it "returns the available users" do
          allow(principal_loader)
            .to receive(:user_values)
            .and_return([[nil, user_1.id.to_s]])

          expect(instance.allowed_values)
            .to contain_exactly([nil, user_1.id.to_s])
        end
      end
    end
  end
end
