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

class ServiceResult
  attr_accessor :success,
                :errors,
                :result,
                :dependent_results

  def initialize(success: false,
                 errors: nil,
                 result: nil)
    self.success = success
    self.result = result
    self.errors = if errors
                    errors
                  elsif result.respond_to?(:errors)
                    result.errors
                  else
                    ActiveModel::Errors.new(self)
                  end

    self.dependent_results = []
  end

  alias success? :success

  def failure?
    !success?
  end

  def merge!(other)
    merge_success!(other)
    merge_dependent!(other)
  end

  def all_results
    [result] + dependent_results.map(&:result)
  end

  def all_errors
    [errors] + dependent_results.map(&:errors)
  end

  def self_and_dependent
    [self] + dependent_results
  end

  def add_dependent!(dependent)
    merge_success!(dependent)

    inner_results = dependent.dependent_results
    dependent.dependent_results = []

    dependent_results << dependent
    self.dependent_results += inner_results
  end

  private

  def merge_success!(other)
    self.success &&= other.success
  end

  def merge_dependent!(other)
    self.dependent_results += other.dependent_results
  end
end
