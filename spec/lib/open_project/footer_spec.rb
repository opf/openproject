#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'open_project/footer'

describe OpenProject::Footer do
  describe '.add_content' do
    context 'empty content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("OpenProject", "footer")
      end
      it {OpenProject::Footer.content.class.should == Hash}
      it {OpenProject::Footer.content["OpenProject"].should == "footer"}
    end

    context 'existing content' do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("OpenProject", "footer")
        OpenProject::Footer.add_content("footer_2", "footer 2")
      end

      it { OpenProject::Footer.content.count.should == 2}
      it { OpenProject::Footer.content.should == {"OpenProject" => "footer", "footer_2" => "footer 2"}}
    end
  end
end
