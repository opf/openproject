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

module OpenProject::Documents::Patches
  module HashSeparatorPatch
    def self.mixin!
      base = ::OpenProject::TextFormatting::Matchers::LinkHandlers::HashSeparator
      base.prepend InstanceMethods
      base.singleton_class.prepend ClassMethods
    end

    module InstanceMethods
      def render_document
        if document = Document.visible.find_by_id(oid)
          link_to document.title,
                  { only_path: context[:only_path],
                    controller: '/documents',
                    action: 'show',
                    id: document },
                  class: 'document'
        end
      end
    end

    module ClassMethods
      def allowed_prefixes
        super + %w[document]
      end
    end
  end
end
