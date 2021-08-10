import { exportEntity } from 'discourse/lib/export-csv';

export default {
  setupComponent(attrs, component) {
    const setting = Discourse.SiteSettings.legal_extended_user_download_admin;
    const user = component.currentUser;
    const allowed = (function(setting) {
      switch(setting) {
        case 'disabled':
          return false;
        case 'admins_only':
          return user.admin;
        case 'admins_and_staff':
          return user.staff;
        default:
          return false;
      }
    })(setting);

    component.set('showAdminUserExport', allowed);
  },

  actions: {
    exportAdminUserArchive(user) {
      bootbox.confirm(
        I18n.t("user.download_archive.confirm_all_admin", { username: user.username }),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        confirmed => confirmed ? exportEntity('admin_user_archive', { user_id: user.id }) : null
      );
    }
  }
}
