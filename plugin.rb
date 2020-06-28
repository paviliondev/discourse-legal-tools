# name: discourse-legal-tools
# about: Tools to help with legal compliance when using Discourse
# version: 2.5.0
# author: Angus McLeod

load File.expand_path('../models/legal_extended_user_download_admin_site_setting.rb', __FILE__)

after_initialize do
  load File.expand_path('../lib/export_csv_file_extension.rb', __FILE__)

  require_dependency 'jobs/regular/export_csv_file'
  class Jobs::ExportCsvFile
    prepend ExtendedDownloadExportExtension
  end

  require_dependency 'guardian'
  class ::Guardian
    prepend ExtendedDownloadGuardianExtension
  end

  require_dependency 'export_csv_controller'
  class ::ExportCsvController
    before_action :ensure_staff, if: -> { admin_user_archive }
    prepend ExtendedDownloadControllerExtension
  end

  module LegalUploadsControllerExtension
    def show
      return render_404 if !RailsMultisite::ConnectionManagement.has_db?(params[:site])
      RailsMultisite::ConnectionManagement.with_connection(params[:site]) do |db|
        if upload = Upload.find_by(sha1: params[:sha]) || Upload.find_by(id: params[:id], url: request.env["PATH_INFO"])
          if upload.original_filename && upload.original_filename.start_with?('user-archive-')
            if current_user.nil? || upload.user_id.nil? || (current_user.id != upload.user_id)
              return render_404
            end
          end
        end
      end
      super
    end
  end

  class ::UploadsController
    prepend LegalUploadsControllerExtension
  end


end
