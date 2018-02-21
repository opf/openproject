#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

def aggregate_parent_array(example, acc)
  # We have to manually check parent groups for with_ee:,
  # since they are being ignored otherwise
  example.example_group.parents.each do |parent|
    if parent.respond_to?(:metadata) && parent.metadata[:with_ee]
      acc.merge(parent.metadata[:with_ee])
    end
  end

  acc
end

RSpec.configure do |config|
  config.before(:each) do |example|
    allowed = example.metadata[:with_ee]
    if allowed.present?
      allowed = aggregate_parent_array(example, allowed.to_set)

      allow(EnterpriseToken).to receive(:allows_to?).and_call_original
      allowed.each do |k|
        allow(EnterpriseToken)
          .to receive(:allows_to?)
          .with(k)
          .and_return true
      end
    end
  end
end
