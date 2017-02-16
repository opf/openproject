#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting::Macros
  class MacroDescriptor
    attr_reader :prefix, :id, :desc, :params, :with_content, :meta

    def initialize(prefix:nil, id:nil, desc:nil, params:[], legacy_support:{}, legacy:false,
                   meta: {}, with_content: nil, stateful: false, post_process:false)
      @prefix = prefix
      @id = id
      @desc = desc
      @params = params
      @meta = meta
      @legacy_support = legacy_support
      @legacy = legacy.nil? ? false : legacy
      @with_content = with_content
      @stateful = stateful.nil? ? false : stateful
      @post_process = post_process.nil? ? false : post_process
    end

    def qname
      "#{self.prefix}:#{self.id}"
    end

    def valid?
      !@prefix.nil? && !@id.nil
    end

    def legacy?
      @legacy
    end

    def post_process?
      @post_process
    end

    def stateful?
      @stateful
    end

    def legacy_support?
      !@legacy_support.nil?
    end

    def legacy_id
      if legacy_support? and not @legacy_support[:id].nil?
        @legacy_support[:id]
      else
        @id
      end
    end

    def with_content?
      !@with_content.nil?
    end
  end
end
