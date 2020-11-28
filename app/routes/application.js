import Route from '@ember/routing/route'
import I18nMixin from 'ember-i18next/mixins/i18n'
import LngDetector from 'i18next-browser-languagedetector'
import ENV from 'fer-resume/config/environment';
import { action } from '@ember/object';

export default class ApplicationRoute extends Route.extend(I18nMixin) {
  async beforeModel() {
    super.beforeModel(...arguments)
    await this.i18n.i18next.use(LngDetector)
    return this.i18n.initLibraryAsync()
  }

  model() {
    return this.store.findRecord('resume', ENV.resumeIDs[this.i18n.locale]);
  }

  @action
  switchLocale(context) {
    this.i18n.set('locale', context.target.value);
    this.refresh();
  }
}
