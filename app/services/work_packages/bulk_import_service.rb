# frozen_string_literal: true

require "csv"
require "nokogiri"
require "zip"

class WorkPackages::BulkImportService < BaseServices::BaseCallable
  HEADERS = {
    "subject" => :subject,
    "type" => :type,
    "description" => :description,
    "status" => :status,
    "priority" => :priority,
    "assignee" => :assigned_to,
    "start date" => :start_date,
    "due date" => :due_date,
    "estimated hours" => :estimated_hours,
    "% complete" => :done_ratio
  }.freeze

  SAMPLE = [
    ["Subject", "Type", "Description", "Status", "Priority", "Assignee", "Start date", "Due date", "Estimated hours", "% Complete"],
    ["Prepare project brief", "Task", "Describe the project scope", "New", "Normal", "", "2026-09-08", "2026-09-10", "8", "0"]
  ].freeze

  attr_reader :user, :project, :file

  def initialize(user:, project:, file:)
    super()
    @user = user
    @project = project
    @file = file
  end

  def perform
    rows = parse_rows
    errors = []
    created = []

    WorkPackage.transaction do
      rows.each_with_index do |row, index|
        begin
          call = WorkPackages::CreateService.new(user: user).call(attributes_for(row))
          if call.success?
            created << call.result
          else
            errors << "Row #{index + 2}: #{call.errors.full_messages.to_sentence}"
          end
        rescue ArgumentError => e
          errors << "Row #{index + 2}: #{e.message}"
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      error = ServiceResult.new(success: false, result: nil)
      error.errors.add(:base, errors.join("\n"))
      error
    else
      ServiceResult.new(success: true, result: created)
    end
  rescue ArgumentError, CSV::MalformedCSVError, Zip::Error, Nokogiri::XML::SyntaxError => e
    result = ServiceResult.new(success: false, result: nil)
    result.errors.add(:base, "Could not read the uploaded file: #{e.message}")
    result
  end

  def self.sample_csv
    CSV.generate(headers: true) { |csv| SAMPLE.each { |row| csv << row } }
  end

  private

  def parse_rows
    raise ArgumentError, "Please choose a CSV or XLSX file." unless file

    case File.extname(file.original_filename).downcase
    when ".csv"
      CSV.parse(file.read, headers: true).map(&:to_h)
    when ".xlsx"
      parse_xlsx
    else
      raise ArgumentError, "Only CSV and XLSX files are supported."
    end
  end

  def parse_xlsx
    Zip::File.open(file.path) do |archive|
      shared_strings = parse_shared_strings(archive)
      sheet = archive.read("xl/worksheets/sheet1.xml")
      xml = Nokogiri::XML(sheet)
      rows = xml.xpath("//*[local-name()='row']").map do |row|
        cells = {}
        row.xpath("./*[local-name()='c']").each do |cell|
          reference = cell["r"].to_s[/\A[A-Z]+/]
          value = cell.at_xpath("./*[local-name()='v']")&.text.to_s
          value = shared_strings[value.to_i] if cell["t"] == "s"
          cells[reference] = value
        end
        cells
      end
      header_row = rows.shift || {}
      columns = column_names(header_row)
      headers = columns.map { |column| header_row.fetch(column, "").to_s }
      rows.map { |row| headers.zip(row.values_at(*columns)).to_h }
    end
  end

  def parse_shared_strings(archive)
    entry = archive.find_entry("xl/sharedStrings.xml")
    return [] unless entry

    Nokogiri::XML(archive.read(entry)).xpath("//*[local-name()='si']").map do |string|
      string.xpath(".//*[local-name()='t']").map(&:text).join
    end
  end

  def column_names(row)
    row&.keys&.sort_by { |name| name.chars.reduce(0) { |value, char| value * 26 + char.ord - 64 } } || []
  end

  def attributes_for(row)
    values = row.to_h.transform_keys { |key| HEADERS[key.to_s.strip.downcase] }.compact
    attributes = values.slice(:subject, :description, :start_date, :due_date, :estimated_hours, :done_ratio)
    attributes[:project] = project
    attributes[:type] = find_required(Type, values[:type], "type") if values[:type].present?
    attributes[:status] = find_required(Status, values[:status], "status") if values[:status].present?
    attributes[:priority] = find_required(IssuePriority, values[:priority], "priority") if values[:priority].present?
    attributes[:assigned_to] = find_user(values[:assigned_to]) if values[:assigned_to].present?
    attributes
  end

  def find_required(model, value, name)
    record = model.find_by(name: value)
    raise ArgumentError, "Unknown #{name} '#{value}'." unless record

    record
  end

  def find_user(value)
    user = User.find_by(login: value) || User.find_by(mail: value)
    raise ArgumentError, "Unknown assignee '#{value}'." unless user

    user
  end
end