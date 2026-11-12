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

module StepWizard
  class FooterComponent < ViewComponent::Base
    include OpPrimer::ComponentHelpers

    renders_one :progress_bar, lambda { |**progress_bar_args|
      progress_bar_args[:size] ||= :small

      Primer::Beta::ProgressBar.new(**progress_bar_args).tap do |progress_bar|
        progress_bar.with_item(percentage: progress_percentage)
      end
    }

    renders_one :back_button, lambda { |**back_button_args|
      back_button_args[:scheme] ||= :invisible
      back_button_args[:color] ||= :muted
      back_button_args[:tag] ||= :a

      Primer::Beta::Button.new(**back_button_args).with_content(I18n.t("button_back")).tap do |back_button|
        back_button.with_leading_visual_icon(icon: :"arrow-left")
      end
    }

    renders_one :cancel_button, lambda { |**cancel_button_args|
      cancel_button_args[:tag] ||= :a

      Primer::Beta::Button.new(**cancel_button_args).with_content(I18n.t("button_cancel"))
    }

    renders_one :continue_button, lambda { |**continue_button_args|
      continue_button_args[:scheme] ||= :primary
      continue_button_args[:type] ||= :submit

      Primer::Beta::Button.new(**continue_button_args).with_content(I18n.t("button_continue"))
    }

    renders_one :submit_button, lambda { |**submit_button_args|
      label = submit_button_args.delete(:label) || I18n.t("button_complete")
      submit_button_args[:scheme] ||= :primary
      submit_button_args[:type] ||= :submit

      Primer::Beta::Button.new(**submit_button_args).with_content(label)
    }

    def initialize(form_identifier:, total_steps:, current_step:)
      super()

      @form_identifier = form_identifier
      @total_steps = total_steps
      @current_step = current_step
    end

    private

    attr_reader :form_identifier, :total_steps, :current_step

    def progress_percentage
      return 0 if total_steps.zero?

      (current_step.to_f / total_steps * 100).round
    end

    def first_step?
      current_step == 1
    end

    def last_step?
      current_step >= total_steps
    end
  end
end
