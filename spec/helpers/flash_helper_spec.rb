#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe FlashHelper, type: :helper do
  describe '#render_flash_messages' do
    it 'renders a flash-messages tag' do
      expect(helper.render_flash_messages).to be_html_eql( %{
        <flash-messages ng-init="messages = {}"></flash-messages>
      })
    end

    it 'renders the flash message as a serialized js object' do
      flash[:notice] = "My notice"
      flash[:error] = "OMG! Error"

      expect(helper.render_flash_messages).to be_html_eql( %{
        <flash-messages
          ng-init=
          "messages = {&#39;notice&#39;:&#39;My notice&#39;,&#39;error&#39;:&#39;OMG! Error&#39;}">
        </flash-messages>
      })
    end

    it 'renders the flash.now messages as a serialized js object' do
      flash.now[:notice] = "My notice"
      flash.now[:error] = "OMG! Error"

      expect(helper.render_flash_messages).to be_html_eql( %{
        <flash-messages
          ng-init=
          "messages = {&#39;notice&#39;:&#39;My notice&#39;,&#39;error&#39;:&#39;OMG! Error&#39;}">
        </flash-messages>
      })
    end
  end
end
