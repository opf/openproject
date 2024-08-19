#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

# Disable the test adapter for the given classes
# allowing GoodJob to handle execution and scheduling,
# which in turn allows us to check concurrency controls etc.
RSpec.configure do |config|
  config.around(:example, :with_good_job) do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    good_job_adapter = GoodJob::Adapter.new(execution_mode: :inline)

    begin
      classes = Array(example.metadata[:with_good_job])
      unless classes.all? { |cls| cls <= ApplicationJob }
        raise ArgumentError.new("Pass the ApplicationJob subclasses you want to disable the test adapter on.")
      end

      classes.each(&:disable_test_adapter)
      ActiveJob::Base.queue_adapter = good_job_adapter
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
      classes.each { |cls| cls.enable_test_adapter(original_adapter) }
      good_job_adapter&.shutdown
    end
  end

  config.around(:example, :with_good_job_batches) do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    good_job_adapter = GoodJob::Adapter.new(execution_mode: :external)

    classes = Array(example.metadata[:with_good_job_batches])
    unless classes.all? { |cls| cls <= ApplicationJob }
      raise ArgumentError.new("Pass the ApplicationJob subclasses you want to disable the test adapter on.")
    end

    classes.each(&:disable_test_adapter)
    ActiveJob::Base.queue_adapter = good_job_adapter
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
    classes.each { |cls| cls.enable_test_adapter(original_adapter) }
    good_job_adapter.shutdown
  end
end
