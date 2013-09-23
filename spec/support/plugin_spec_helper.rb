#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module PluginSpecHelper
  shared_examples_for "customized journal class" do
    describe :save do
      let(:text) { "Lorem ipsum" }
      let(:changed_data) { { :text => [nil, text] } }

      describe "WITHOUT compression" do
        before do
          #we have to save here because changed_data will update (and save) attributes and miss an ID
          journal.save!
          journal.changed_data = changed_data

          journal.reload
        end

        it { journal.changed_data[:text][1].should == text }
      end
    end
  end
end
