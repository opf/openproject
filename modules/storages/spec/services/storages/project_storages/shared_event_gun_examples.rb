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

RSpec.shared_examples "an event gun" do |event|
  %i[automatic manual inactive].each do |mode|
    context "when project_folder mode is #{mode}" do
      it "fires an appropriate event" do
        allow(OpenProject::Notifications).to(receive(:send))
        model_instance.project_folder_mode = mode

        subject

        expect(OpenProject::Notifications).to(
          have_received(:send)
          .with(event, project_folder_mode: mode,
                       project_folder_mode_previously_was: model_instance.project_folder_mode_previously_was,
                       storage: model_instance.storage)
        )
      end
    end
  end
end
