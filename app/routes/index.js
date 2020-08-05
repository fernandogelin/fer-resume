import Route from '@ember/routing/route';
import ENV from 'fer-resume/config/environment';
import { action } from '@ember/object';
import I18nMixin from 'ember-i18next/mixins/i18n';

export default class IndexRoute extends Route.extend(I18nMixin) {
  model() {
    return this.store.findRecord('resume', ENV.resumeIDs[this.i18n.locale]);
  }

  @action
  switchLocale(context) {
    this.i18n.set('locale', context.target.value);
    this.refresh();
  }
}
