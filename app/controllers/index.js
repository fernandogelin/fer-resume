import Controller from '@ember/controller';
import { computed } from '@ember/object';
import I18nMixin from 'ember-i18next/mixins/i18n';

export default class IndexController extends Controller.extend(I18nMixin) {
  @computed('i18n.locale')
  get isEN() {
    return this.i18n.locale === 'en-se';
  }

  @computed('i18n.locale')
  get isPT() {
    return this.i18n.locale === 'pt-br';
  }
}
