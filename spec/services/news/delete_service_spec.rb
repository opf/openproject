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

RSpec.describe News::DeleteService, type: :model do
  let(:news) { build_stubbed(:news, project:) }
  let(:project) { build_stubbed(:project) }

  let(:instance) { described_class.new(model: news, user: actor) }

  subject do
    instance.call
  end

  shared_examples "deletes the news" do
    it do
      expect(news).to receive(:destroy).and_return(true)
      expect(subject).to be_success
    end
  end

  shared_examples "does not delete the news" do
    it do
      expect(news).not_to receive(:destroy)
      expect(subject).not_to be_success
    end
  end

  context "with allowed user" do
    let(:actor) { build_stubbed(:user) }

    before do
      mock_permissions_for(actor) do |mock|
        mock.allow_in_project(:manage_news, project:)
      end
    end

    it_behaves_like "deletes the news"
  end
end
