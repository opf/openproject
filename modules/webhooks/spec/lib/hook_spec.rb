#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
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

require File.expand_path('../../spec_helper', __FILE__)


describe OpenProject::Webhooks::Hook do
  describe '#relative_url' do
    let(:hook) { OpenProject::Webhooks::Hook.new('myhook')}

    it "should return the correct URL" do
      expect(hook.relative_url).to eql('webhooks/myhook')
    end
  end

  describe '#handle' do
    let(:probe) { lambda{} }
    let(:hook) { OpenProject::Webhooks::Hook.new('myhook', &probe) }

    before do
      expect(probe).to receive(:call).with(hook, 1, 2, 3)
    end

    it 'should execute the callback with the correct parameters' do
      hook.handle(1, 2, 3)
    end
  end
end
