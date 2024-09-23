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

RSpec.describe Queries::UpdateContract do
  include_context "with queries contract"

  describe "private query" do
    let(:public) { false }

    context "when user is author" do
      let(:user) { current_user }

      context "when user has no permission to save" do
        let(:permissions) { %i(edit_work_packages) }

        it_behaves_like "contract user is unauthorized"
      end

      context "when user has permission to save" do
        let(:permissions) { %i(save_queries) }

        it_behaves_like "contract is valid"

        context "when the query becomes public" do
          before do
            query.public = true
          end

          it_behaves_like "contract user is unauthorized"

          context "with permission to manage public" do
            let(:permissions) { %i(save_queries manage_public_queries) }

            it_behaves_like "contract is valid"
          end
        end
      end
    end

    context "when user is someone else" do
      let(:user) { build_stubbed(:user) }
      let(:permissions) { %i(save_queries) }

      it_behaves_like "contract user is unauthorized"

      context "with permission to manage public" do
        let(:permissions) { %i(manage_public_queries) }

        it_behaves_like "contract user is unauthorized"

        context "when the query becomes public" do
          before do
            query.public = true
          end

          # Other users cannot publish private queries
          it_behaves_like "contract user is unauthorized"
        end
      end
    end
  end

  describe "public query" do
    let(:public) { true }
    let(:user) { nil }

    context "when user has no permission to save" do
      let(:permissions) { %i() }

      it_behaves_like "contract user is unauthorized"
    end

    context "when user has permission to manage public" do
      let(:permissions) { %i(manage_public_queries) }

      it_behaves_like "contract is valid"

      context "when the query becomes private" do
        before do
          query.public = false
        end

        it_behaves_like "contract is valid"

        context "when the query user is deleted" do
          let(:user) { DeletedUser.first }

          it_behaves_like "contract user is unauthorized"
        end
      end
    end

    context "when user has permission to save only own" do
      let(:permissions) { %i(save_queries) }

      it_behaves_like "contract user is unauthorized"

      context "when user is author" do
        let(:user) { current_user }

        # Cannot make a query private if cannot manage_public_queries
        it_behaves_like "contract user is unauthorized"
      end
    end
  end
end
