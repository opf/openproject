#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe AvatarHelper, type: :helper do
  let(:user) { FactoryGirl.build_stubbed(:user) }

  def expected_image_tag(digest, options = {})
    tag_options = options.reverse_merge(title: user.name,
                                        alt: 'Gravatar',
                                        class: 'avatar').delete_if { |key, value| value.nil? || key == :ssl }

    image_tag expected_url(digest, options), tag_options
  end

  def expected_url(digest, options = {})
    ssl = !!options[:ssl]

    host = ssl ?
             'https://secure.gravatar.com' :
             'http://gravatar.com'

    "#{host}/avatar/#{digest}?secure=#{ssl}"
  end

  describe 'avatar' do
    context 'when enabled', with_settings: { gravatar_enabled?: true } do
      describe 'ssl dependent on protocol settings' do
        context 'with https protocol', with_settings: { protocol: 'https' } do
          it "should be set to secure if protocol is 'https'" do
            expect(helper.default_gravatar_options[:secure]).to be true
          end
        end

        context 'with http protocol', with_settings: { protocol: 'http' } do
          it "should be set to unsecure if protocol is 'http'" do
            expect(helper.default_gravatar_options[:secure]).to be false
          end
        end
      end

      describe 'default avatar dependent on settings' do
        context 'with wavatars', with_settings: { gravatar_default: 'Wavatars' } do
          it 'should be set to value of setting' do
            expect(helper.default_gravatar_options[:default]).to eq 'Wavatars'
          end
        end

        context 'when empty' do
          it 'should be set to nil' do
            expect(helper.default_gravatar_options[:default]).to be_nil
          end
        end
      end

      context 'with http', with_settings: { protocol: 'http' } do
        it 'should return a gravatar image tag if a user is provided' do
          digest = Digest::MD5.hexdigest(user.mail)
          expect(helper.avatar(user)).to be_html_eql(expected_image_tag(digest))
        end

        it 'should return a gravatar url if a user is provided' do
          digest = Digest::MD5.hexdigest(user.mail)
          expect(helper.avatar_url(user)).to eq(expected_url(digest))
        end
      end

      context 'with https', with_settings: { protocol: 'https' } do
        it 'should return a gravatar image tag with ssl if the request was ssl required' do
          digest = Digest::MD5.hexdigest(user.mail)
          expect(helper.avatar(user)).to be_html_eql(expected_image_tag(digest, ssl: true))
        end

        it 'should return a gravatar image tag with ssl if the request was ssl required' do
          digest = Digest::MD5.hexdigest(user.mail)
          expect(helper.avatar_url(user)).to eq(expected_url(digest, ssl: true))
        end
      end

      it 'should return an empty string if a non parsable (e-mail) string is provided' do
        expect(helper.avatar('just the name')).to eq('')
      end

      it 'should return an empty string if nil is provided' do
        expect(helper.avatar(nil)).to eq('')
      end

      it 'should return a gravatar image tag if a parsable e-mail string is provided' do
        mail = '<e-mail@mail.de>'
        digest = Digest::MD5.hexdigest('e-mail@mail.de')

        expect(helper.avatar(mail)).to be_html_eql(expected_image_tag(digest, title: nil))
      end

      it 'should return a gravatar image tag if a parsable e-mail string is provided' do
        mail = '<e-mail@mail.de>'
        digest = Digest::MD5.hexdigest('e-mail@mail.de')

        expect(helper.avatar_url(mail)).to eq(expected_url(digest))
      end

      it 'should return an empty string if a non parsable (e-mail) string is provided' do
        expect(helper.avatar_url('just the name')).to eq('')
      end

      it 'should return an empty string if nil is provided' do
        expect(helper.avatar_url(nil)).to eq('')
      end
    end
  end

  context 'when disabled', with_settings: { gravatar_enabled?: false } do
    it 'should return an empty string if gravatar is disabled' do
      expect(helper.avatar(user)).to eq('')
    end

    it 'should return an empty string if gravatar is disabled' do
      expect(helper.avatar_url(user)).to eq('')
    end
  end
end
