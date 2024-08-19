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

RSpec.describe WikiPages::CreateContract do
  it_behaves_like "wiki page contract" do
    subject(:contract) { described_class.new(page, current_user, options: {}) }

    let(:page) do
      WikiPage.new(wiki: page_wiki,
                   title: page_title,
                   slug: page_slug,
                   protected: page_protected,
                   parent: page_parent,
                   text: page_text,
                   author: page_author).tap do |page|
        page.extend(OpenProject::ChangedBySystem)
        page.changed_by_system(changed_by_system)

        allow(page)
          .to receive(:project)
          .and_return(page_wiki&.project)
      end
    end

    let(:changed_by_system) do
      if page_author
        { "author_id" => [nil, page_author.id] }
      else
        {}
      end
    end

    describe "#validation" do
      context "if the author is different from the current user" do
        let(:page_author) { build_stubbed(:user) }

        it "is invalid" do
          expect_valid(false, author: :not_current_user)
        end
      end

      context "if the author was not set by system" do
        let(:changed_by_system) { {} }

        it "is invalid" do
          expect_valid(false, author_id: %i(error_readonly))
        end
      end
    end
  end
end
