import Route from '@ember/routing/route'
import ENV from 'fer-resume/config/environment';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default class ApplicationRoute extends Route {
  @service intl

  async beforeModel() {
    super.beforeModel(...arguments)
  }

  model() {
    return this.store.findRecord('resume', ENV.resumeIDs[this.intl.get('primaryLocale')]);
  }

  @action
  switchLocale(context) {
    console.log(context.target.value);
    this.intl.setLocale(context.target.value);
    this.refresh();
  }
}
