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

RSpec.describe Queries::RecurringMeetings::Filters::AuthorFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :author_id }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end
  end

  describe "#where clause" do
    let(:project) { create(:project) }
    let(:author1) { create(:user) }
    let(:author2) { create(:user) }
    let!(:series_by_author1) { create(:recurring_meeting, project:, author: author1) }
    let!(:series_by_author2) { create(:recurring_meeting, project:, author: author2) }

    let(:instance) do
      described_class.create!(name: :author_id, operator:, values:)
    end

    context 'for "="' do
      let(:operator) { "=" }
      let(:values) { [author1.id.to_s] }

      it "returns only recurring meetings by that author" do
        result = RecurringMeeting.where(instance.where)

        expect(result).to include(series_by_author1)
        expect(result).not_to include(series_by_author2)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }
      let(:values) { [author1.id.to_s] }

      it "excludes recurring meetings by that author" do
        result = RecurringMeeting.where(instance.where)

        expect(result).not_to include(series_by_author1)
        expect(result).to include(series_by_author2)
      end
    end

    context 'for "*"' do
      let(:operator) { "*" }
      let(:values) { [] }

      it "returns all recurring meetings with any author" do
        result = RecurringMeeting.where(instance.where)

        expect(result).to include(series_by_author1, series_by_author2)
      end
    end
  end
end
