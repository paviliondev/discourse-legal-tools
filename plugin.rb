# name: discourse-legal-tools
# about: Tools to help with legal compliance when using Discourse
# version: 0.1
# author: Angus McLeod

after_initialize do
  load File.expand_path('../lib/export_csv_file_extension.rb', __FILE__)

  if SiteSetting.legal_extended_user_download
    require_dependency 'jobs/regular/export_csv_file'
    class Jobs::ExportCsvFile
      prepend ExportCsvFileExtension
    end
  end
end
