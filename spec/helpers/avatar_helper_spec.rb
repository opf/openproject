#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe AvatarHelper, :type => :helper do
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
        expect(helper.avatar(user)).to eq(expected_image_tag(digest))
      end
    end

    it "should return a gravatar image tag with ssl if the request was ssl required" do
      digest = Digest::MD5.hexdigest(user.mail)
      allow(helper.request).to receive(:ssl?).and_return(true)

      with_settings :gravatar_enabled => '1' do
        expect(helper.avatar(user)).to eq(expected_image_tag(digest, :ssl => true))
      end
    end

    it "should return a gravatar image tag if a parsable e-mail string is provided" do
      with_settings :gravatar_enabled => '1' do
        mail = "<e-mail@mail.de>"
        digest = Digest::MD5.hexdigest("e-mail@mail.de")

        expect(helper.avatar(mail)).to eq(expected_image_tag(digest))
      end
    end

    it "should return an empty string if a non parsable (e-mail) string is provided" do
      with_settings :gravatar_enabled => '1' do
        expect(helper.avatar('just the name')).to eq('')
      end
    end

    it "should return an empty string if nil is provided" do
      with_settings :gravatar_enabled => '1' do
        expect(helper.avatar(nil)).to eq('')
      end
    end

    it "should return an empty string if gravatar is disabled" do
      with_settings :gravatar_enabled => '0' do
        expect(helper.avatar(user)).to eq('')
      end
    end

    it "should return an empty string if any error is produced in the lib" do
      allow(helper).to receive(:gravatar).and_raise(ArgumentError)

      with_settings :gravatar_enabled => '1' do
        expect(helper.avatar(user)).to eq('')
      end
    end
  end
end
