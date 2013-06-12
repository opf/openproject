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

require File.expand_path('../../spec_helper', __FILE__)

describe TimelinesColorsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.xml' do
    def fetch
      get 'index', :format => 'xml'
    end
    it_should_behave_like "a controller action with unrestricted access"

    describe 'with no colors available' do
      it 'assigns an empty colors array' do
        get 'index', :format => 'xml'
        assigns(:colors).should == []
      end

      it 'renders the index builder template' do
        get 'index', :format => 'xml'
        response.should render_template('timelines/colors/index', :formats => ["api"])
      end
    end

    describe 'with some colors available' do
      before do
        @created_colors = [
          FactoryGirl.create(:color),
          FactoryGirl.create(:color),
          FactoryGirl.create(:color)
        ]
      end

      it 'assigns an array with all colors' do
        get 'index', :format => 'xml'
        assigns(:colors).should == @created_colors
      end

      it 'renders the index template' do
        get 'index', :format => 'xml'
        response.should render_template('timelines/colors/index', :formats => ["api"])
      end
    end
  end

  describe 'show.xml' do
    describe 'with unknown color' do
      if false # would like to write it this way
        it 'returns status code 404' do
          get 'show', :id => '1337', :format => 'xml'

          response.status.should == '404 Not Found'
        end

        it 'returns an empty body' do
          get 'show', :id => '1337', :format => 'xml'

          response.body.should be_empty
        end

      else # but have to write it that way
        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :id => '1337', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'with an available color' do
      before do
        @available_color = FactoryGirl.create(:color, :id => '1337')
      end

      def fetch
        get "show", :id => '1337', :format => 'xml'
      end
      it_should_behave_like "a controller action with unrestricted access"


      it 'assigns the available color' do
        get 'show', :id => '1337', :format => 'xml'
        assigns(:color).should == @available_color
      end

      it 'renders the show template' do
        get 'show', :id => '1337', :format => 'xml'
        response.should render_template('timelines/colors/show', :formats => ["api"])
      end
    end
  end

  describe "index.html" do
    def fetch
      get "index"
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "new.html" do
    def fetch
      get 'new'
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "create.html" do
    def fetch
      post 'create', :color => FactoryGirl.build(:color).attributes
    end
    def expect_redirect_to
      Regexp.new(colors_path)
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "edit.html" do
    def fetch
      @available_color = FactoryGirl.create(:color, :id => '1337')
      get 'edit', :id => '1337'
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "update.html" do
    def fetch
      @available_color = FactoryGirl.create(:color, :id => '1337')
      put 'update', :id => '1337', :color => { 'name' => 'blubs' }
    end
    def expect_redirect_to
      colors_path
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "move.html" do
    def fetch
      @available_color = FactoryGirl.create(:color, :id => '1337')
      post 'move', :id => '1337', :color => {:move_to => 'highest'}
    end
    def expect_redirect_to
      colors_path
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "confirm_destroy.html" do
    def fetch
      @available_color = FactoryGirl.create(:color, :id => '1337')
      get 'confirm_destroy', :id => '1337'
    end
    it_should_behave_like "a controller action with require_admin"
  end

  describe "destroy.html" do
    def fetch
      @available_color = FactoryGirl.create(:color, :id => '1337')
      post 'destroy', :id => '1337'
    end
    def expect_redirect_to
      colors_path
    end
    it_should_behave_like "a controller action with require_admin"
  end
end
