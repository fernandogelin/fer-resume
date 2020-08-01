import Component from '@glimmer/component'
import { inject as service } from '@ember/service'
import { action } from '@ember/object'
import { tracked } from '@glimmer/tracking'

export default class LangSelectComponent extends Component {
  @service router
  @service i18n
  @tracked isEn = this.i18n.locale === 'en-se'
  @tracked isPt = this.i18n.locale === 'pt-br'

  @action
  changeLocale(context) {
    let newLocale = context.target.value
    this.i18n.locale = newLocale
    this.isEn = newLocale === 'en-se'
    this.isPt = newLocale === 'pt-br'
    this.router.transitionTo('resume', {
      queryParams: { lang: newLocale }
    })
  }
}
