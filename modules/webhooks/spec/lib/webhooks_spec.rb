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


describe OpenProject::Webhooks do
  describe '.register_hook' do
    after do
      OpenProject::Webhooks.unregister_hook('testhook1')
    end

    it 'should succeed' do
      OpenProject::Webhooks.register_hook('testhook1') {}
    end
  end

  describe '.find' do
    let!(:hook) { OpenProject::Webhooks.register_hook('testhook3') {} }

    after do
      OpenProject::Webhooks.unregister_hook('testhook3')
    end

    it 'should succeed' do
      expect(OpenProject::Webhooks.find('testhook3')).to equal(hook)
    end
  end

  describe '.unregister_hook' do
    let(:probe) { lambda{} }

    before do
      OpenProject::Webhooks.register_hook('testhook2', &probe)

    end

    it 'should result in the hook no longer being found' do
      OpenProject::Webhooks.unregister_hook('testhook2')
      expect(OpenProject::Webhooks.find('testhook2')).to be_nil
    end
  end

end
