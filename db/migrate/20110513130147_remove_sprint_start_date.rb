class RemoveSprintStartDate < ActiveRecord::Migration
  def self.up
    Version.reset_column_information

    unless Version.column_names.include?("start_date")
      raise "Abort! This migration depends on Chiliproject www.chiliproject.org/issues/279! Migrations were not executed in the correct order"
    end

    Version.transaction do
      Version.all.each do |version|
        if version.sprint_start_date.present? and version.read_attribute(:start_date).present? and
           version.sprint_start_date != version.read_attribute(:start_date)

          raise "Version #{version.id} has a start date and a sprint start date! Migrations were not executed in the correct order"

        elsif version.sprint_start_date.present? and version.read_attribute(:start_date).blank?
          puts "Copying sprint_start_date to start_date for Sprint #{version.id} - #{version.name.inspect}"
          version.start_date = version.sprint_start_date
          version.save!
        end
      end
    end

    remove_column(:versions, :sprint_start_date)
  end

  def self.down
    add_column(:versions, :sprint_start_date, :date)

    Version.reset_column_information
    Version.all.each do |version|
      version.sprint_start_date = version.start_date
      version.save!
    end
  end
end
