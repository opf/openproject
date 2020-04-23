#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module SCM
    module Adapters
      module CheckoutInstructions
        ##
        # Returns the checkout URL for the given repository
        # based on this adapter's knowledge
        def checkout_url(repository, base_url, path)
          checkout_url = if local?
                           ::URI.join(with_trailing_slash(base_url),
                                      repository.repository_identifier)
                         else
                           url
                         end

          if subtree_checkout? && path.present?
            ::URI.join(with_trailing_slash(checkout_url), path)
          else
            checkout_url
          end
        end

        ##
        # Returns whether the SCM vendor supports subtree checkout
        def subtree_checkout?
          false
        end

        ##
        # Returns the checkout command for this vendor
        def checkout_command
          raise NotImplementedError
        end

        private

        ##
        # Ensure URL has a trailing slash.
        # Needed for base URL, because URI.join will otherwise
        # assume a relative resource.
        def with_trailing_slash(url)
          url = url.to_s

          url << '/' unless url.end_with?('/')
          url
        end
      end
    end
  end
end
