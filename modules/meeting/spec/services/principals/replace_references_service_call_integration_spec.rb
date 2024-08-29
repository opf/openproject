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
require_module_spec_helper

RSpec.describe Principals::ReplaceReferencesService, "#call", type: :model do
  shared_let(:principal) { create(:user) }
  shared_let(:to_principal) { create(:user) }

  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  let(:instance) do
    described_class.new
  end

  shared_examples "replaces the creator" do
    before do
      model
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "replaces principal with to_principal" do
      service_call
      model.reload

      expect(model.author).to eql to_principal
    end
  end

  context "with MeetingAgendaItem" do
    it_behaves_like "replaces the creator" do
      let(:model) { create(:meeting_agenda_item, author: principal) }
    end
  end
end
