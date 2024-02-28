import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { exportEntity } from 'discourse/lib/export-csv';
import { inject as service } from '@ember/service';

export default class UserExportComponent extends Component {
  @service currentUser;
  @service siteSettings;
  @service dialog;
  @tracked showAdminUserExport = false;

  constructor() {
    super(...arguments);
    this.initializeComponent();
  }

  initializeComponent() {
    const setting = this.siteSettings.legal_extended_user_download_admin;
    const user = this.currentUser;
    this.showAdminUserExport = this.calculateAllowed(setting, user);
  }

  calculateAllowed(setting, user) {
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
  }

  @action
  exportAdminUserArchive(user) {
    console.log(user);
    this.dialog.confirm({
      message: I18n.t("user.download_archive.confirm_all_admin", { username: user.username }),
      didConfirm: () => {
        exportEntity('admin_user_archive', { user_id: user.id });
      }
    });
  }
}
