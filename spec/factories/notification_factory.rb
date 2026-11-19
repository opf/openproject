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

FactoryBot.define do
  factory :notification do
    subject { "MyText" }
    read_ian { false }
    mail_reminder_sent { false }
    mail_alert_sent { false }
    reason { :mentioned }
    recipient factory: :user
    resource { association :work_package }

    trait :for_milestone do
      resource { association :work_package, :is_milestone }
    end
    # journal and actor are not listed by intend.
    # They will be set in the after_build callback.
    # But not listing them allows to identify if they have been provided, even if nil has been provided.

    callback(:after_build) do |notification, evaluator|
      # Default the journal and the actor associations but only if:
      # * it is not a date alert
      # * the values haven't been overridden (including setting them to nil).
      unless notification.reason_date_alert_due_date? || notification.reason_date_alert_start_date?
        notification.journal ||= notification.resource.journals.last unless evaluator.overrides?(:journal)
        notification.actor ||= notification.journal.try(:user) unless evaluator.overrides?(:actor)
      end
    end
  end
end
