# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JobLogging do
  let(:log_output) { StringIO.new }
  let(:logger) do
    plain_logger = ActiveSupport::Logger.new(log_output)
    plain_logger.formatter = ->(severity, _time, _progname, message) { "#{severity} #{message}\n" }
    ActiveSupport::TaggedLogging.new(plain_logger)
  end
  let!(:original_logger) { ActiveJob::Base.logger }

  let(:plain_job_class) do
    Class.new(ApplicationJob) do
      include Import::JobLogging

      private

      def log_context = { jira_import_id: arguments.first, jira_project_id: nil }
    end
  end

  before do
    ActiveJob::Base.logger = logger
    stub_const("TestImportJob", job_class)
  end

  after { ActiveJob::Base.logger = original_logger }

  def logged_lines
    log_output.string.lines(chomp: true).map { |line| line.sub(/\[ActiveJob\] \[[^\]]+\] \[[^\]]+\] /, "") }
  end

  context "with a job that succeeds" do
    let(:job_class) do
      Class.new(plain_job_class) do
        def perform(_jira_import_id)
          with_log_context(jira_object_id_or_name: "High") { logger.debug "Fetched priority" }
        end
      end
    end

    before { TestImportJob.perform_now(7) }

    it "logs its start and finish at info level, tagged with its context" do
      expect(logged_lines).to include("INFO [jira_import_id:7] TestImportJob started",
                                      "INFO [jira_import_id:7] TestImportJob finished")
    end

    it "tags the lines of a log context with the job's context as well" do
      expect(logged_lines).to include("DEBUG [jira_import_id:7] [jira_object_id_or_name:High] Fetched priority")
    end

    it "leaves out context values that are nil" do
      expect(log_output.string).not_to include("jira_project_id")
    end
  end

  context "with a job that fails" do
    let(:job_class) do
      Class.new(plain_job_class) do
        def perform(_jira_import_id)
          raise "Jira answered 500"
        end
      end
    end

    it "re-raises the error" do
      expect { TestImportJob.perform_now(7) }.to raise_error(RuntimeError, "Jira answered 500")
    end

    it "logs one failure at error level, tagged with its context, and no finish" do
      expect { TestImportJob.perform_now(7) }.to raise_error(RuntimeError)

      expect(logged_lines.grep(/TestImportJob failed/))
        .to eq(["ERROR [jira_import_id:7] TestImportJob failed: Jira answered 500"])
      expect(logged_lines).not_to include(a_string_including("TestImportJob finished"))
    end
  end

  context "with a job that fails inside a log context" do
    let(:job_class) do
      Class.new(plain_job_class) do
        def perform(_jira_import_id)
          with_log_context(jira_object_id_or_name: "High") { raise "Priority High is invalid" }
        end
      end
    end

    it "logs the failure once, tagged with the inner context" do
      expect { TestImportJob.perform_now(7) }.to raise_error(RuntimeError)

      expect(logged_lines.grep(/TestImportJob failed/))
        .to eq(["ERROR [jira_import_id:7] [jira_object_id_or_name:High] TestImportJob failed: Priority High is invalid"])
    end
  end

  context "with a job that rescues an error inside a log context" do
    let(:job_class) do
      Class.new(plain_job_class) do
        def perform(_jira_import_id)
          with_log_context(jira_object_id_or_name: "Low") do
            raise KeyError, "Priority Low is gone"
          rescue KeyError
            logger.warn "Skipping priority"
          end
        end
      end
    end

    before { TestImportJob.perform_now(7) }

    it "logs no failure" do
      expect(logged_lines).not_to include(a_string_including("TestImportJob failed"))
    end

    it "logs its finish" do
      expect(logged_lines).to include("INFO [jira_import_id:7] TestImportJob finished")
    end
  end

  context "with a job whose failure a rescue_from handler takes care of" do
    let(:job_class) do
      Class.new(plain_job_class) do
        rescue_from(StandardError) { |error| logger.info "Handled #{error.message}" }

        def perform(_jira_import_id)
          raise "Jira answered 500"
        end
      end
    end

    let(:failure_line) { "ERROR [jira_import_id:7] TestImportJob failed: Jira answered 500" }

    before { TestImportJob.perform_now(7) }

    it "logs the failure before the handler runs" do
      expect(logged_lines).to include(failure_line, "INFO Handled Jira answered 500")
      expect(logged_lines.index(failure_line)).to be < logged_lines.index("INFO Handled Jira answered 500")
    end

    it "logs no finish" do
      expect(logged_lines).not_to include(a_string_including("TestImportJob finished"))
    end
  end

  context "with an iteration job" do
    let(:job_class) do
      Class.new(ApplicationJob) do
        include JobIteration::Iteration
        include Import::JobLogging

        def build_enumerator(_jira_import_id, _interrupt_after, cursor:)
          enumerator_builder.array(%w[first second], cursor:)
        end

        def each_iteration(item, _jira_import_id, interrupt_after)
          logger.debug "Processing #{item}"
          @interrupted = item == interrupt_after
        end

        private

        def job_should_exit? = @interrupted || super

        def log_context = { jira_import_id: arguments.first }
      end
    end

    it "logs its start once and its finish when the iteration completes" do
      TestImportJob.perform_now(7, nil)

      expect(logged_lines.grep(/TestImportJob (started|finished)/))
        .to eq(["INFO [jira_import_id:7] TestImportJob started", "INFO [jira_import_id:7] TestImportJob finished"])
    end

    it "logs no finish when interrupted and no second start when resumed" do
      TestImportJob.perform_now(7, "first")
      expect(logged_lines).not_to include(a_string_including("TestImportJob finished"))

      ActiveJob::Base.execute(ActiveJob::Base.queue_adapter.enqueued_jobs.last)

      expect(logged_lines.grep(/TestImportJob (started|finished)/))
        .to eq(["INFO [jira_import_id:7] TestImportJob started", "INFO [jira_import_id:7] TestImportJob finished"])
    end
  end

  context "with a progressable job that is aborted" do
    let(:jira_import) { instance_double(Import::JiraImport, in_state?: true) }
    let(:job_class) do
      Class.new(Import::ProgressableJob) do
        include Import::JobLogging

        def build_enumerator(jira_import_id, cursor:)
          @jira_import = Import::JiraImport.find(jira_import_id)
          enumerator_builder.array(%w[first second], cursor:)
        end

        def each_iteration(_item, _jira_import_id); end

        private

        def log_context = { jira_import_id: arguments.first }
      end
    end

    before do
      allow(jira_import).to receive(:reload).and_return(jira_import)
      allow(Import::JiraImport).to receive(:find).and_return(jira_import)
    end

    it "logs the abort as its failure and no finish" do
      expect { TestImportJob.perform_now(7) }.to raise_error(Import::ProgressableJob::AbortionError)

      expect(logged_lines).to include("ERROR [jira_import_id:7] TestImportJob failed: Job was aborted")
      expect(logged_lines).not_to include(a_string_including("TestImportJob finished"))
    end
  end
end
