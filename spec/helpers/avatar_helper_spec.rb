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

  describe :avatar do
    it "should produce an image tag pointing to gravatar" do
      # turn on avatars
      Setting.gravatar_enabled = '1'
      mail = user.mail
      assert helper.avatar(user).include?(Digest::MD5.hexdigest(mail))
      assert helper.avatar("#{user.name} <#{mail}>").include?(Digest::MD5.hexdigest(mail))
      assert_nil helper.avatar('admin')
      assert_nil helper.avatar(nil)

      # turn off avatars
      Setting.gravatar_enabled = '0'
      assert_equal '', helper.avatar(user)
    end
  end
end

