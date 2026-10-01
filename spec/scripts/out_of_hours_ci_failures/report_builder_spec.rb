# frozen_string_literal: true

require "spec_helper"

module OutOfHoursCiFailures
end

load Rails.root.join("script/report_out_of_hours_ci_failures")

RSpec.describe OutOfHoursCiFailures::ReportBuilder do
  let(:options) do
    {
      days: 30,
      include_pr_runs: false,
      json: false,
      timezone: "Europe/Berlin",
      workflow: "test-core.yml"
    }
  end

  let(:client) { instance_spy(OutOfHoursCiFailures::GithubClient) }
  let(:builder) { described_class.new(options:, client:) }
  let(:run_id) { 1001 }

  before do
    allow(Time).to receive(:current).and_return(Time.zone.parse("2026-03-08 12:00:00 UTC"))
  end

  it "classifies boundary times using the configured timezone" do
    stub_runs(
      workflow(run_id:, created_at: "2026-03-03T07:59:00Z")
    )
    stub_jobs(run_id => failed_jobs("Feature tests"))
    stub_logs("spec/features/example_spec.rb:10")

    summary = builder.build.first

    expect(summary.out_of_hours_count).to eq(1)
    expect(summary.in_hours_count).to eq(0)
  end

  it "ignores build failures and keeps only unit and feature test failures" do
    stub_runs(
      workflow(run_id:, created_at: "2026-03-03T08:00:00Z"),
      workflow(run_id: 1002, created_at: "2026-03-03T09:00:00Z")
    )
    stub_jobs(
      run_id => build_failure_jobs,
      1002 => failed_jobs("Unit tests")
    )
    stub_logs("spec/models/example_spec.rb:12")

    summaries = builder.build

    expect(summaries.map(&:location)).to eq(["spec/models/example_spec.rb:12"])
  end

  it "classifies repeated out-of-hours failures on multiple branches as likely datetime-sensitive" do
    stub_runs(
      workflow(run_id:, branch: "dev", created_at: "2026-03-03T07:59:00Z"),
      workflow(
        run_id: 1002,
        branch: "release/17.2",
        created_at: "2026-03-04T18:00:00Z"
      )
    )
    stub_jobs(
      run_id => failed_jobs("Feature tests"),
      1002 => failed_jobs("Feature tests")
    )
    stub_logs("spec/features/example_spec.rb:10")

    summary = builder.build.first

    expect(summary.classification).to eq("likely datetime-sensitive")
  end

  it "classifies failures seen in and out of hours as likely generic flaky" do
    stub_runs(
      workflow(run_id:, branch: "dev", created_at: "2026-03-03T07:59:00Z"),
      workflow(
        run_id: 1002,
        branch: "release/17.2",
        created_at: "2026-03-04T10:00:00Z"
      )
    )
    stub_jobs(
      run_id => failed_jobs("Feature tests"),
      1002 => failed_jobs("Feature tests")
    )
    stub_logs("spec/features/example_spec.rb:10")

    summary = builder.build.first

    expect(summary.classification).to eq("likely generic flaky")
  end

  it "classifies repeated failures on a single branch as likely regression" do
    stub_runs(
      workflow(
        run_id:,
        created_at: "2026-03-03T07:59:00Z",
        branch: "feature/foo",
        event: "push"
      ),
      workflow(
        run_id: 1002,
        created_at: "2026-03-04T08:30:00Z",
        branch: "feature/foo",
        event: "push"
      )
    )
    stub_jobs(
      run_id => failed_jobs("Unit tests"),
      1002 => failed_jobs("Unit tests")
    )
    stub_logs("spec/models/example_spec.rb:12")

    summaries = described_class.new(options: options.merge(include_pr_runs: true), client:).build

    expect(summaries.first.classification).to eq("likely regression")
  end

  def stub_runs(*runs)
    allow(client).to receive(:workflow_runs).and_return(
      { "workflow_runs" => runs },
      { "workflow_runs" => [] }
    )
  end

  def stub_jobs(jobs_by_run_id)
    allow(client).to receive(:jobs) do |id|
      jobs_by_run_id.fetch(id)
    end
  end

  def stub_logs(location)
    allow(client).to receive(:log).and_return(job_log(location))
  end

  def workflow(run_id:, created_at:, branch: "dev", event: "push")
    {
      "id" => run_id,
      "run_number" => run_id,
      "html_url" => "https://github.com/opf/openproject/actions/runs/#{run_id}",
      "head_branch" => branch,
      "event" => event,
      "created_at" => created_at
    }
  end

  def failed_jobs(step_name)
    {
      "jobs" => [
        {
          "id" => 9001,
          "conclusion" => "failure",
          "steps" => [
            { "name" => step_name, "conclusion" => "failure" }
          ]
        }
      ]
    }
  end

  def build_failure_jobs
    {
      "jobs" => [
        {
          "id" => 9002,
          "conclusion" => "failure",
          "steps" => [
            { "name" => "Build", "conclusion" => "failure" }
          ]
        }
      ]
    }
  end

  def job_log(location)
    "2026-03-03T08:00:00.0000000Z rspec #{location} # example failure\n"
  end
end
