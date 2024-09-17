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

RSpec.shared_examples_for "safeguarded API" do
  it { expect(last_response).to have_http_status(:not_found) }
end

RSpec.shared_examples_for "valid activity request" do
  shared_let(:admin) { create(:admin) }
  let(:status_code) { 200 }

  before do
    allow(User).to receive(:current).and_return(admin)
  end

  it { expect(last_response).to have_http_status(status_code) }

  describe "response body" do
    subject { last_response.body }

    it { is_expected.to be_json_eql("Activity::Comment".to_json).at_path("_type") }

    it { is_expected.to be_json_eql(comment.to_json).at_path("comment/raw") }
  end
end

RSpec.shared_examples_for "invalid activity request" do
  shared_let(:admin) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(admin)
  end

  it { expect(last_response).to have_http_status(:unprocessable_entity) }
end
