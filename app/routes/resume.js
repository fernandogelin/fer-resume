import Route from '@ember/routing/route'
import I18nMixin from 'ember-i18next/mixins/i18n'

export default class ResumeRoute extends Route.extend(I18nMixin) {
  queryParams = {
    lang: {
      refreshModel: true
    }
  }
  model(params) {
    const id =
      params.lang === 'en-se'
        ? 'fbc7c5a8630ee55274ec7ee89f62dd5f'
        : 'da99c3da93c806d4d6319279c844ad72'
    return this.store.findRecord('gist', id).then(m => m.resume)
  }
}
