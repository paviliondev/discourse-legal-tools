# name: discourse-legal-tools
# about: Tools to help with legal compliance when using Discourse
# version: 0.1
# author: Angus McLeod

DiscourseEvent.on(:custom_wizard_ready) do
  if defined?(CustomWizard) == 'constant' && CustomWizard.class == Module
    unless PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: 'privacy_update')
      CustomWizard::Wizard.add_wizard(File.read(File.join(
        Rails.root, 'plugins', 'discourse-legal-tools', 'config', 'wizards', 'privacy_update.json'
      )))
      SiteSetting.wizard_redirect_exclude_paths += '|privacy'
    end
  end
end

after_initialize do
  load File.expand_path('../lib/export_csv_file_extension.rb', __FILE__)

  if SiteSetting.legal_extended_user_download
    require_dependency 'jobs/regular/export_csv_file'
    class Jobs::ExportCsvFile
      prepend ExportCsvFileExtension
    end
  end
end
