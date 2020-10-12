require 'fileutils'

module OpenProject::Bim::BcfXml
  class Exporter < ::WorkPackage::Exporter::Base
    include Redmine::I18n

    def initialize(object, options = {})
      object.add_filter('bcf_issue_associated', '=', ['t'])
      super(object, options)
    end

    def current_user
      User.current
    end

    def list
      Dir.mktmpdir do |dir|
        files = create_bcf! dir

        zip = zip_folder dir, files
        yield success(zip)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to export work package list #{e} #{e.message}"
      raise e
    end

    def list_from_api
      Dir.mktmpdir do |dir|
        files = create_bcf! dir

        zip_folder dir, files
      end
    rescue StandardError => e
      Rails.logger.error "Failed to export work package list #{e} #{e.message}"
      raise e
    end

    def success(zip)
      WorkPackage::Exporter::Result::Success
        .new format: :xls,
             content: zip,
             title: bcf_filename,
             mime_type: 'application/octet-stream'
    end

    def bcf_filename
      # We often have an internal query name that is not meant
      # for public use or was given by a user.
      if query.name.present? && query.name != '_'
        return sane_filename("#{query.name}.bcf")
      end

      sane_filename(
        "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} \
        #{format_time_as_date(Time.now, '%Y-%m-%d')}.bcf"
      )
    end

    def zip_folder(dir, files)
      zip_file = File.join(dir, bcf_filename)

      Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
        files.each do |file|
          name = file.sub("#{dir}/", "")
          zip.add name, file
        end
      end

      File.open(zip_file, 'r')
    end

    def create_bcf!(bcf_folder)
      manifest_file = write_manifest(bcf_folder)
      files = [manifest_file]

      work_packages.find_each do |wp|
        # Update or create the BCF issue from the given work package
        issue = IssueWriter.update_from!(wp)

        # Create a folder for the issue
        issue_folder = topic_folder_for(bcf_folder, issue)

        # Append the markup itself
        files << topic_markup_file(issue_folder, issue)

        # Append any viewpoints
        files.concat viewpoints_for(issue_folder, issue)

        # TODO additional files such as BIM snippets
      end

      files
    end

    ##
    # Write the manifest file <dir>/bcf.version
    def write_manifest(dir)
      File.join(dir, "bcf.version").tap do |manifest_file|
        dump_file manifest_file, manifest_xml
      end
    end

    ##
    # Create and return the issue folder
    # /dir/<uuid>/
    def topic_folder_for(dir, issue)
      File.join(dir, issue.uuid).tap do |issue_dir|
        Dir.mkdir issue_dir
      end
    end

    ##
    # Write each work package BCF
    def topic_markup_file(issue_dir, issue)
      File.join(issue_dir, 'markup.bcf').tap do |file|
        dump_file file, issue.markup
      end
    end

    ##
    # Write viewpoints
    def viewpoints_for(issue_dir, issue)
      [].tap do |files|
        issue.viewpoints.find_each do |vp|
          vp_file = File.join(issue_dir, "#{vp.uuid}.xml")
          snapshot_file = File.join(issue_dir, "#{vp.uuid}#{vp.snapshot.extension}")

          # Copy the files
          dump_file vp_file, ViewpointWriter.new(vp).to_xml
          FileUtils.cp vp.snapshot.local_path, snapshot_file

          files << vp_file << snapshot_file
        end
      end
    end

    def manifest_xml
      Nokogiri::XML::Builder.new do |xml|
        xml.comment created_by_comment
        xml.Version "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                    "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
                    "VersionId" => "2.1" do
          xml.DetailedVersion "2.1"
        end
      end.to_xml
    end

    def dump_file(path, content)
      File.open(path, "w") do |f|
        f.write content
      end
    end

    def created_by_comment
      " Created by #{Setting.app_title} #{OpenProject::VERSION} at #{Time.now} "
    end
  end
end
