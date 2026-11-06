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

RSpec.configure do |config|
  config.before do
    # Clear any mail deliveries
    # This happens automatically for :mailer specs
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear

    TokenBucketState.delete_all
    FactoryBot.create :token_bucket_state, :email_limit_per_day
  end

  config.append_after do
    # Cleanup after specs changing locale explicitly or
    # by calling code in the app setting changing the locale.
    I18n.locale = :en unless I18n.locale == :en

    RequestStore.clear!
  end

  config.append_after(:all) do
    # Ensure models don't leak between test through RequestStore if it is used in after(:all)
    RequestStore.clear!
  end

  # We don't want this to be reported on CI as it breaks the build
  unless ENV["CI"]
    config.append_after(:suite) do
      [User.not_builtin, Project, WorkPackage].each do |cls|
        next if cls.count == 0

        raise <<-EOS
          Your specs left #{cls.count} #{cls.model_name.plural} in the DB
          Did you use before(:all) instead of before
          or forget to kill the instances in a after(:all)?
        EOS
      end
    end
  end
end
