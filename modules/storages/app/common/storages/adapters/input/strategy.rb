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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Input
      Strategy = Data.define(:key, :user, :storage, :use_cache, :token) do
        private_class_method :new

        def self.build(key:, user: nil, storage: nil, use_cache: true, token: nil, contract: StrategyContract.new)
          contract.call(key:, user:, use_cache:, storage:, token:).to_monad.fmap { |result| new(**result.to_h) }
        end

        def with_user(user)
          with(user:)
        end

        def with_cache(use_cache)
          with(use_cache:)
        end

        def with_token(token)
          with(token:)
        end
      end
    end
  end
end
