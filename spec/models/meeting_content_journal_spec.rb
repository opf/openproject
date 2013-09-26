#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

require 'journal/meeting_content_journal'

describe Journal do
  include PluginSpecHelper

  let(:journal) { FactoryGirl.build(:meeting_content_journal) }

  it_should_behave_like "customized journal class"
end
