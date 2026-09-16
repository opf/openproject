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

module Admin
  module Labels
    class FormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      FORM_ID = "admin-label-form"

      attr_reader :state

      delegate :create?, to: :state

      # `model` (not `label`) is deliberate: this component is the Rails form
      # template context for its nested primer_form_with block, and a reader
      # named `label` would shadow ActionView::Helpers::FormHelper#label.
      def initialize(label:, state:)
        super(label)

        @state = ActiveSupport::StringInquirer.new(state.to_s)
      end

      private

      def http_method
        create? ? :post : :patch
      end

      def form_url
        create? ? admin_labels_path : admin_label_path(model)
      end
    end
  end
end
