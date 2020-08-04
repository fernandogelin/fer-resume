import Route from '@ember/routing/route';
import ENV from 'fer-resume/config/environment';
import { action, computed } from '@ember/object';
import I18nMixin from 'ember-i18next/mixins/i18n';

export default class IndexRoute extends Route.extend(I18nMixin) {
    model() {
        return this.store.findRecord('resume', ENV.resumeIDs[this.i18n.locale]);
    }

    @computed('i18n.locale')
    get isEN() {
        return (this.i18n.locale === 'en-se')
    }

    @computed('i18n.locale')
    get isPT() {
        return (this.i18n.locale === 'pt-br')
    }

    @action
    switchLocale(context) {
        this.i18n.set('locale', context.target.value);
        this.refresh();
    }

    setupController(controller, model) {
        super.setupController(controller, model);
    
        controller.set('isEN', this.isEN);
        controller.set('isPT', this.isPT);
    }
}
