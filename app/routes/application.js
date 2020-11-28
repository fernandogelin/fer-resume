import Route from '@ember/routing/route'
import ENV from 'fer-resume/config/environment';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default class ApplicationRoute extends Route {
  @service intl

  async beforeModel() {
    super.beforeModel(...arguments)
    this.intl.setLocale([this.intl.get('primaryLocale'), 'en-se']);
  }

  model() {
    const primaryLocale = this.intl.get('primaryLocale')
    const locales = this.intl.get('locales')
    const fallbackLocale = locales.includes(primaryLocale) ? primaryLocale : 'en-se'
    return this.store.findRecord('resume', ENV.resumeIDs[fallbackLocale]);
  }

  @action
  switchLocale(context) {
    console.log(context.target.value);
    this.intl.setLocale([context.target.value, 'en-se']);
    this.refresh();
  }
}
