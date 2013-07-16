#-- encoding: UTF-8
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

describe AvatarHelper do
  let(:user) { FactoryGirl.build_stubbed(:user) }

  def expected_image_tag(digest, options = {})
    # there are some attributes in here that are wrong but are returned by the
    # bundled plugin.  I will not fix the lib at the given moment. I would rather, we
    # remove the bundled gem and reference one in the Gemfile or
    # implement the thing ourselves.

    host = options[:ssl] ?
             "https://secure.gravatar.com" :
             "http://www.gravatar.com"

    expected_src = "#{host}/avatar/#{digest}?rating=PG&size=50&default="

    image_tag expected_src, :class => "gravatar",
                            :title => '',
                            :ssl => options[:ssl] || false,
                            :alt => '',
                            :default => '',
                            :rating => 'PG'
  end

  describe :avatar do
    it "should return a gravatar image tag if a user is provided" do
      digest = Digest::MD5.hexdigest(user.mail)

      with_settings :gravatar_enabled => '1' do
        helper.avatar(user).should == expected_image_tag(digest)
      end
    end

    it "should return a gravatar image tag with ssl if the request was ssl required" do
      digest = Digest::MD5.hexdigest(user.mail)
      helper.request.stub!(:ssl?).and_return(true)

      with_settings :gravatar_enabled => '1' do
        helper.avatar(user).should == expected_image_tag(digest, :ssl => true)
      end
    end

    it "should return a gravatar image tag if a parsable e-mail string is provided" do
      with_settings :gravatar_enabled => '1' do
        mail = "<e-mail@mail.de>"
        digest = Digest::MD5.hexdigest("e-mail@mail.de")

        helper.avatar(mail).should == expected_image_tag(digest)
      end
    end

    it "should return an empty string if a non parsable (e-mail) string is provided" do
      with_settings :gravatar_enabled => '1' do
        helper.avatar('just the name').should == ''
      end
    end

    it "should return an empty string if nil is provided" do
      with_settings :gravatar_enabled => '1' do
        helper.avatar(nil).should == ''
      end
    end

    it "should return an empty string if gravatar is disabled" do
      with_settings :gravatar_enabled => '0' do
        helper.avatar(user).should == ''
      end
    end

    it "should return an empty string if any error is produced in the lib" do
      helper.stub!(:gravatar).and_raise(ArgumentError)

      with_settings :gravatar_enabled => '1' do
        helper.avatar(user).should == ''
      end
    end
  end
end

