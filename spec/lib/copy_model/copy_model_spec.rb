#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require 'tableless_spec_helper'

class CopyDummy < Tableless
  include CopyModel

  safe_attributes "safe_attribute1",
                  "safe_attribute2"

  column :safe_attribute1, :string
  column :safe_attribute2, :string
  column :unsafe_attribute, :string

  column :relation1_id, :integer
  column :relation2_id, :integer
  column :relation3_id, :integer

  belongs_to :relation1
  belongs_to :relation2
  belongs_to :relation3

  def copy_relation1(other)
    self.relation1 = other.relation1
  end

  def copy_relation2(other)
    self.relation2 = other.relation2
  end
end

class Relation1 < Tableless
end

class Relation2 < Tableless
end

class Relation3 < Tableless
end

describe "Copying Models" do

  describe "copying attributes" do
    let(:dummy) { CopyDummy.new }

    it "should copy safe attributes" do
      dummy.safe_attribute1 = "foo"
      dummy.safe_attribute2 = "bar"

      copy = CopyDummy.copy(dummy)

      dummy.safe_attribute1.should == copy.safe_attribute1
      dummy.safe_attribute2.should == copy.safe_attribute2
    end

    it "should not copy unsafe attributes" do
      dummy.unsafe_attribute = "foo"
      dummy.safe_attribute1 = "foo"

      copy = CopyDummy.copy(dummy)

      dummy.safe_attribute1.should == copy.safe_attribute1
      dummy.unsafe_attribute.should_not == copy.unsafe_attribute
    end
  end
end
