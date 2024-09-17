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

RSpec.describe API::V3::Relations::RelationCollectionRepresenter do
  let(:work_package) do
    build_stubbed(:work_package)
  end
  let(:representer) do
    described_class.new(relations,
                        self_link:,
                        current_user: user)
  end

  let(:relations) do
    build_stubbed_list(:relation,
                       3,
                       from: work_package,
                       to: build_stubbed(:work_package))
  end

  let(:user) do
    build_stubbed(:user)
  end

  def self_link
    "a link that is provided"
  end

  context "generation" do
    subject(:collection) { representer.to_json }

    it_behaves_like "unpaginated APIv3 collection",
                    3,
                    "a link that is provided",
                    "Relation"
  end
end
