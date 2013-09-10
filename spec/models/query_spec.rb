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

describe Query do
  describe 'available_columns'
    let(:query) { FactoryGirl.build(:query) }

    context 'with issue_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_true
      end
    end

    context 'with issue_done_ratio disabled' do
      before do
        Setting.stub(:issue_done_ratio).and_return('disabled')
      end

      it 'should NOT include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_nil
      end
    end
end
