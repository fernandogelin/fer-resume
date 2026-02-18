import Controller from '@ember/controller';
import { type Registry as Services, service } from '@ember/service';
import { action } from '@ember/object';

export default class ApplicationController extends Controller {
  @service declare intl: Services['intl'];
  @service declare router: Services['router'];
  @service declare resume: Services['resume'];

  get currentLocale(): string {
    return this.intl.primaryLocale ?? 'en-se';
  }

  @action
  switchLocale(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const locale = target.value;
    this.intl.setLocale([locale, 'en-se']);
    this.resume.setLocale(locale);
    this.router.refresh();
  }
}
