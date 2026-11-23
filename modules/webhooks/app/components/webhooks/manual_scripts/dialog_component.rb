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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Webhooks
  module ManualScripts
    class DialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "manual-script-dialog"

      def initialize(script:, work_package:)
        super
        @script = script
        @work_package = work_package
      end

      def call
        render(Primer::Alpha::Dialog.new(id: DIALOG_ID, title: @script.label, size: :xlarge,
                                         test_selector: DIALOG_ID, data: { keep_open_on_submit: true })) do |dialog|
          dialog.with_header(variant: :large)
          render(BodyComponent.new(script: @script, work_package: @work_package))
        end
      end
    end
  end
end
