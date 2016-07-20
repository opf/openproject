#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module PluginSpecHelper
  shared_examples_for 'customized journal class' do
    describe '#save' do
      let(:text) { 'Lorem ipsum' }
      let(:changed_data) { { text: [nil, text] } }

      describe 'WITHOUT compression' do
        before do
          # we have to save here because changed_data will update (and save) attributes and miss an ID
          journal.save!
          journal.changed_data = changed_data

          journal.reload
        end

        it { expect(journal.changed_data[:text][1]).to eq(text) }
      end
    end
  end
end
