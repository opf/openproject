#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'
require 'representable/json'

describe Representable do
  let(:object) { Struct.new(:title).new('test') }

  class ReverseNamingStrategy
    def call(name)
      name.reverse
    end
  end

  describe 'as_strategy with lambda' do
    class UpcaseRepresenter < Representable::Decorator
      include Representable::JSON

      self.as_strategy = ->(name) { name.upcase }

      property :title
    end

    it { expect(UpcaseRepresenter.new(object).to_json).to eql("{\"TITLE\":\"test\"}") }
  end

  describe 'as_strategy with class responding to #call?' do
    class ReverseRepresenter < Representable::Decorator
      include Representable::JSON

      self.as_strategy = ReverseNamingStrategy.new

      property :title
    end

    it { expect(ReverseRepresenter.new(object).to_json).to eql("{\"eltit\":\"test\"}") }
  end

  describe 'as_strategy with class not responding to #call?' do
    it 'raises error' do
      expect do
        class FailRepresenter < Representable::Decorator
          include Representable::JSON

          self.as_strategy = ::Object.new

          property :title
        end
      end.to raise_error(RuntimeError)
    end
  end
end
