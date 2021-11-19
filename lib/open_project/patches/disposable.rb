#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

# Disposable from 0.6.0 on includes Forwardable into every
# class inheriting from Disposable::Twin. OpenProject
# uses Disposable::Twin for the contracts.
# Including Forwardable overwrites the rails core_ext delegate
# on which e.g. ActiveModel::Naming relies.
OpenProject::Patches.patch_gem_version 'disposable', '6.0.1' do
  # The patch thus loads the module including Forwardable, then removes the
  # code and defines its own empty module.
  module Disposable
    class Twin
      module Property

      end
    end
  end

  require "disposable/twin/property/unnest"
  Disposable::Twin::Property.send(:remove_const, :Unnest)

  module Disposable
    class Twin
      module Property
        module Unnest
          def unnest(_name, _options)
            raise 'Relying on patched away method'
          end
        end
      end
    end
  end

  require 'disposable'
end
