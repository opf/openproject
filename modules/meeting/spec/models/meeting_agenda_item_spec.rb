#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require_relative "../spec_helper"

RSpec.describe MeetingAgendaItem do
  subject { described_class.new(attributes) }

  describe '#duration' do
    let(:attributes) { { title: 'foo', duration_in_minutes: } }

    context 'with a valid duration' do
      let(:duration_in_minutes) { 60 }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'with a negative duration' do
      let(:duration_in_minutes) { -1 }

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be greater than or equal to 0."
      end
    end

    context 'with a duration that is too large' do
      let(:duration_in_minutes) { 10000000000 }

      it 'is valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be less than or equal to 1440."
      end
    end

    context 'with max duration' do
      let(:duration_in_minutes) { 1440 }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'with overmax duration' do
      let(:duration_in_minutes) { 1441 }

      it 'is valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be less than or equal to 1440."
      end
    end
  end
end
