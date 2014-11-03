#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::Activities::ActivitiesAPI, type: :request do
  include Rack::Test::Methods

  let(:admin) { FactoryGirl.create(:admin) }
  let(:comment) { "This is a test comment!" }

  shared_examples_for "safeguarded API" do
    it { expect(last_response.status).to eq(403) }
  end

  shared_examples_for "valid activity request" do
    before { allow(User).to receive(:current).and_return(admin) }

    subject { JSON.parse(last_response.body) }

    it { expect(subject['_type']).to eq("Activity::Comment") }

    it { expect(subject['rawComment']).to eq(comment) }
  end

  shared_examples_for "invalid activity request" do |message|
    before { allow(User).to receive(:current).and_return(admin) }

    it_behaves_like 'constraint violation', message
  end

  describe "PATCH /api/v3/activities/:activityId" do
    let(:work_package) { FactoryGirl.create(:work_package) }
    let(:wp_journal) { FactoryGirl.build(:journal_work_package_journal) }
    let(:journal) { FactoryGirl.create(:work_package_journal,
                                       data: wp_journal,
                                       journable_id: work_package.id) }

    shared_context "edit activity" do
      before { patch "/api/v3/activities/#{journal.id}",
                   { comment: comment }.to_json, { 'CONTENT_TYPE' => 'application/json' } }
    end

    it_behaves_like "safeguarded API" do
      include_context "edit activity"
    end

    it_behaves_like "valid activity request" do
      include_context "edit activity"
    end

    it_behaves_like "invalid activity request", 'An error occurred' do
      before do
        allow_any_instance_of(Journal).to receive(:save).and_return(false)
        allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return(['An error occurred'])
      end

      include_context "edit activity"
    end
  end
end
