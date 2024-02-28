import { withPluginApi } from 'discourse/lib/plugin-api';
import { exportUserArchive } from 'discourse/lib/export-csv';

export default {
  name: 'legal-edits',
  initialize() {
    withPluginApi('0.8.12', api => {
      api.modifyClass("controller:preferences/account", {
        pluginId: "discourse-legal-tools",
        actions: {
          exportUserArchive() {
            const extendedUserDownload = this.siteSettings.legal_extended_user_download;
            if (extendedUserDownload) {
              this.dialog.yesNoConfirm({
                message: I18n.t("user.download_archive.confirm_all"),
                didConfirm: () => {
                  exportUserArchive();
                }
              });
            } else {
              this._super();
            }
          }
        }
      })
    })
  }
}
