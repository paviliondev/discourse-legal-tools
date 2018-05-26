require_dependency 'enum_site_setting'

class LegalExtendedUserDownloadAdminSiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    return true if val == ""
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= [
      {
        name: I18n.t('site_settings.legal_extended_user_download_admin_choices.disabled'),
        value: 'disabled'
      },
      {
        name: I18n.t('site_settings.legal_extended_user_download_admin_choices.admins_only'),
        value: 'admins_only'
      },
      {
        name: I18n.t('site_settings.legal_extended_user_download_admin_choices.admins_and_staff'),
        value: 'admins_and_staff'
      }
    ]
  end
end
