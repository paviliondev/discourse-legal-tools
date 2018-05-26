# name: discourse-legal-tools
# about: Tools to help with legal compliance when using Discourse
# version: 0.1
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
end
