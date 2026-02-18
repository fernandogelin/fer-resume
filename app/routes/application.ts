import Route from '@ember/routing/route';
import { type Registry as Services, service } from '@ember/service';
import translationsForEnSe from 'virtual:ember-intl/translations/en-se';
import translationsForPtBr from 'virtual:ember-intl/translations/pt-br';
import type { ResumeData } from 'fer-resume/types/resume';

export default class ApplicationRoute extends Route {
  @service declare intl: Services['intl'];
  @service declare resume: Services['resume'];

  beforeModel(): void {
    this.intl.addTranslations('en-se', translationsForEnSe);
    this.intl.addTranslations('pt-br', translationsForPtBr);
    this.intl.setLocale(['en-se']);
  }

  model(): ResumeData {
    return this.resume.data;
  }
}
