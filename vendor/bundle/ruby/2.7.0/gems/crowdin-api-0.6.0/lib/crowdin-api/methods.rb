module Crowdin
  # A wrapper and interface to the Crowdin api. Please visit the Crowdin developers
  # site for a full explaination of what each of the Crowdin api methods
  # expect and perform.
  #
  # https://crowdin.com/page/api

  class API

    # Add new file to Crowdin project.
    #
    # == Parameters
    #
    # files - Array of files that should be added to Crowdin project.
    # file is a Hash { :dest, :source, :title, :export_pattern }
    # * :dest - file name with path in Crowdin project (required)
    # * :source - path for uploaded file (required)
    # * :title - title in Crowdin UI (optional)
    # * :export_pattern - Resulted file name (optional)
    #
    # Optional:
    # * :branch - a branch name.
    #   If the branch is not exists Crowdin will be return an error:
    #     "error":{
    #       "code":8,
    #       "message":"File was not found"
    #   }
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/add-file?key={project-key}
    #
    def add_file(files, params = {})
      params[:files] = Hash[files.map { |f| [
        f[:dest]               || raise(ArgumentError, "'`:dest`' is required"),
        ::File.open(f[:source] || raise(ArgumentError, "'`:source` is required'"))
      ] }]

      params[:titles] = Hash[files.map { |f| [f[:dest], f[:title]] }]
      params[:titles].delete_if { |_, v| v.nil? }

      params[:export_patterns] = Hash[files.map { |f| [f[:dest], f[:export_pattern]] }]
      params[:export_patterns].delete_if { |_, v| v.nil? }

      params.delete_if { |_, v| v.respond_to?(:empty?) ? !!v.empty? : !v }

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/add-file",
        :query  => params,
      )
    end

    # Upload fresh version of your localization file to Crowdin.
    #
    # == Parameters
    #
    # files - Array of files that should be updated in Crowdin project.
    # file is a Hash { :dest, :source }
    # * :dest - file name with path in Crowdin project (required)
    # * :source - path for uploaded file (required)
    # * :title - title in Crowdin UI (optional)
    # * :export_pattern - Resulted file name (optional)
    #
    # Optional:
    # * :branch - a branch name
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/update-file?key={project-key}
    #
    def update_file(files, params = {})
      params[:files] = Hash[files.map { |f|
        dest = f[:dest] || raise(ArgumentError, "'`:dest` is required'")
        source = ::File.open(f[:source] || raise(ArgumentError, "'`:source` is required'"))
        source.define_singleton_method(:original_filename) do
          dest
        end
        [dest, source]
      }]

      params[:titles] = Hash[files.map { |f| [f[:dest], f[:title]] }]
      params[:titles].delete_if { |_, v| v.nil? }

      params[:export_patterns] = Hash[files.map { |f| [f[:dest], f[:export_pattern]] }]
      params[:export_patterns].delete_if { |_, v| v.nil? }

      params.delete_if { |_, v| v.respond_to?(:empty?) ? !!v.empty? : !v }

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/update-file",
        :query  => params,
      )
    end

    # Upload existing translations to your Crowdin project.
    #
    # == Parameters
    #
    # files - Array of files that should be added to Crowdin project.
    # file is a Hash { :dest, :source }
    #   * :dest - file name with path in Crowdin project (required)
    #   * :source - path for uploaded file (required)
    # language - Target language. With a single call it's possible to upload translations for several
    #   files but only into one of the languages. (required)
    #
    # Optional:
    # * :import_duplicates (default: false)
    # * :import_eq_suggestions (default: false)
    # * :auto_approve_imported (default: false)
    # * :branch - a branch name
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/upload-translation?key={project-key}
    #
    def upload_translation(files, language, params = {})
      params[:files] = Hash[files.map { |f| [
        f[:dest]               || raise(ArgumentError, "`:dest` is required"),
        ::File.open(f[:source] || raise(ArgumentError, "`:source` is required"))
      ] }]

      params[:language] = language

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/upload-translation",
        :query  => params,
      )
    end

    # Download ZIP file with translations. You can choose the language of translation you need or download all of them at once.
    #
    # Note: If you would like to download the most recent translations you may want to use export API method before downloading.
    #
    # Optional:
    # * :output - a name of ZIP file with translations
    # * :branch - a branch name
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/download/{package}.zip?key={project-key}
    #
    def download_translation(language = 'all', params = {})
      request(
        :method  => :get,
        :path    => "/api/project/#{@project_id}/download/#{language}.zip",
        :output  => params.delete(:output),
        :query   => params,
      )
    end

    # Upload your glossarries for Crowdin Project in TBX file format.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/upload-glossary?key={project-key}
    #
    def upload_glossary(file)
      # raise "#{path} file does not exist" unless ::File.exist?(path)
      file = ::File.open(file, 'rb')

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/upload-glossary",
        :query  => { :file => file },
      )
    end

    # Upload your Translation Memory for Crowdin Project in TMX file format.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/upload-tm?key={project-key}
    #
    def upload_tm(file)
      file = ::File.open(file, 'rb')

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/upload-tm",
        :query  => { :file => file },
      )
    end

    # Add directory to Crowdin project.
    #
    # == Parameters
    #
    # name - directory name (with path if nested directory should be created). (required)
    #
    # Optional:
    # * :is_branch - create new branch. Valid values - 0, 1. Only when create root directory.
    # * :branch - a branch name.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/add-directory?key={project-key}
    #
    def add_directory(name, params = {})
      params[:name] = name

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/add-directory",
        :query  => params,
      )
    end

    # Delete Crowdin project directory. All nested files and directories will be deleted too.
    #
    # == Parameters
    #
    # name - Directory path (or just name if the directory is in root) (required)
    # :branch - a branch name (optional)
    #
    # FIXME
    # When you try to remove the branch directory Crowdin will be return an error:
    #   "error":{
    #     "code":17,
    #     "message":"Specified directory was not found"
    #   }
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/delete-directory?key={project-key}
    #
    def delete_directory(name, params = {})
      params[:name] = name

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/delete-directory",
        :query  => params,
      )
    end


    # Rename or change directory attributes.
    #
    # == Parameters
    #
    # name - Full directory path that should be modified (e.g. /MainPage/AboutUs).
    #
    # Optional:
    # * :new_name - new directory name (not contain path, name only)
    # * :title - new directory title to be displayed in Crowdin UI
    # * :export_pattern - new directory export pattern
    # * :branch - a branch name
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/change-directory?key={project-key}
    #
    def change_directory(name, params = {})
      params[:name] = name

      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/change-directory",
        :query  => params,
      )
    end


    # Delete file from Crowdin project. All the translations will be lost without ability to restore them.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/delete-file?key={project-key}
    #
    def delete_file(file)
      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/delete-file",
        :query  => { :file => file },
      )
    end

    # Download Crowdin project glossaries as TBX file.
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/download-glossary?key={project-key}
    #
    def download_glossary(params = {})
      request(
        :method => :get,
        :path   => "/api/project/#{@project_id}/download-glossary",
        :output => params[:output],
      )
    end

    # Download Crowdin project Translation Memory as TMX file.
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/download-tm?key={project-key}
    #
    def download_tm(params = {})
      request(
        :method => :get,
        :path   => "/api/project/#{@project_id}/download-tm",
        :output => params[:output],
      )
    end

    # Export a single translated file from Crowdin.
    #
    # == Parameters
    #
    # file - File name with path in Crowdin project. (required)
    # language - Target language. (required)
    #
    # Optional:
    # * :branch - a branch name
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/export-file?key={project-key}
    #
    def export_file(file, language, params = {})
      params[:file] = file
      params[:language] = language
      request(
        :method => :get,
        :path   => "/api/project/#{@project_id}/export-file",
        :output => params.delete(:output),
        :query  => params,
      )
    end

    # Build ZIP archive with the latest translations.
    #
    # Please note that this method can be invoked only every 30 minutes.
    # Also API call will be ignored if there were no any changes in project since last export.
    #
    # Optional:
    # * :branch - a branch name
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/export?key={project-key}
    #
    def export_translations(params = {})
      request(
        :method => :get,
        :path   => "/api/project/#{@project_id}/export",
        :query  => params,
      )
    end


    # Get supported languages list with Crowdin codes mapped to locale name and standarded codes.
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/project/{project-identifier}/supported-languages?key={project-key}
    #
    def supported_languages
      request(
        :method => :get,
        :path   => "/api/project/#{@project_id}/supported-languages",
      )
    end

    # Track your Crowdin project translation progress by language.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/status?key={project-key}
    #
    def translations_status
      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/status",
      )
    end

    # Get Crowdin Project details.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/info?key={project-key}
    #
    def project_info
      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/info",
      )
    end

    # Create new Crowdin project.
    # Important: The API method requires Account API Key. This key can not be found on your profile pages.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/account/create-project?account-key={account-key}
    #
    def create_project(params = {})
      request(
        :method => :post,
        :path   => "/api/account/create-project",
        :query  => params,
      )
    end

    # Edit Crowdin project.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/edit-project?key={key}
    #
    def edit_project(params = {})
      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/edit-project",
        :query  => params,
      )
    end

    # Delete Crowdin project with all translations.
    #
    # == Request
    #
    # POST https://api.crowdin.com/api/project/{project-identifier}/delete-project?key={project-key}
    #
    def delete_project
      request(
        :method => :post,
        :path   => "/api/project/#{@project_id}/delete-project",
      )
    end

    # Get Crowdin Project details.
    # Important: The API method requires Account API Key. This key can not be found on your profile pages.
    #
    # == Request
    #
    # GET https://api.crowdin.com/api/account/get-projects?account-key={account-key}
    #
    def get_projects(login)
      request(
        :method => :get,
        :path   => "/api/account/get-projects",
        :query  => { :login => login },
      )
    end

  end
end
