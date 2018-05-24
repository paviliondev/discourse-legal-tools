import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  optInIcon: null,
  unsubscribeIcon: null,
  sendingOptIn: false,
  performingUnsubscribe: false,
  optInSpecificUsers: false,
  optInAllSubscribers: false,

  @computed('optInSpecificUsers', 'optInUsernames', 'optInAllSubscribers')
  sendOptInDisabled(optInSpecificUsers, optInUsernames, optInAllSubscribers) {
    if (optInSpecificUsers) {
      return !optInUsernames;
    } else {
      return !optInAllSubscribers;
    }
  },

  @computed('sendingOptIn', 'optInIcon')
  showOptInIcon(sendingOptIn, optInIcon) {
    return !sendingOptIn && optInIcon;
  },

  @computed('performaingUnsubscribe', 'unsubscribeIcon')
  showUnsubscribeIcon(sendingOptIn, unsubscribeIcon) {
    return !sendingOptIn && unsubscribeIcon;
  },

  actions: {
    sendDigestOptIn() {
      this.set('sendingOptIn', true);
      let data = {};

      const optInUsernames = this.get('optInUsernames');
      if (optInUsernames) {
        data['target_users'] = optInUsernames;
      }

      ajax('/admin/legal/digest/opt-in', {
        type: 'POST',
        data
      }).then((result) => {
        if (result.success) {
          this.set('optInIcon', 'tick');
        } else {
          this.set('optInIcon', 'times');
        }
      }).catch(popupAjaxError).finally(() => {
        this.set('sendingOptIn', false);
      })
    },

    unsubscribeFromDigest() {
      this.set('performingUnsubscribe', true);

      const targetUsers = this.get('unsubscribeUsernames');
      if (targetUsers) {
        data['target_users'] = targetUsers;
      }

      ajax('/admin/legal/digest/unsubscribe', {
        type: 'POST',
        data
      }).then((result) => {
        if (result.success) {
          this.set('unsubcribeIcon', 'tick');
        } else {
          this.set('unsubcribeIcon', 'times');
        }
      }).catch(popupAjaxError).finally(() => {
        this.set('performingUnsubscribe', false);
      })
    }
  }
})
