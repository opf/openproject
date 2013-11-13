#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

#-- encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OpenProject::Backlogs::TaskboardCard::CardArea do
  let(:pdf) { Prawn::Document.new(:margin => 0) }

  let(:options) do
    {
      :width => 120.0,
      :height => 12,
      :size => 12,
      :at => [0, 0],
      :single_line => true
    }
  end

  describe '.text_box' do
    it 'shortens long texts' do
      box = OpenProject::Backlogs::TaskboardCard::CardArea.text_box(pdf,
                                             'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                                             options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lorem ipsum dolor[...]'
    end

    it 'does not shorten short texts' do
      box = OpenProject::Backlogs::TaskboardCard::CardArea.text_box(pdf, 'Lorem ipsum', options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lorem ipsum'
    end

    it 'handles multibyte characters gracefully' do
      box = OpenProject::Backlogs::TaskboardCard::CardArea.text_box(pdf,
                                             'Lörëm ïpsüm dölör sït ämët, cönsëctëtür ädïpïscïng ëlït.',
                                             options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lörëm ïpsüm dölör[...]'
    end
  end
end
