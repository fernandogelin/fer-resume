import Controller from '@ember/controller';
import { type Registry as Services, service } from '@ember/service';
import { action } from '@ember/object';

export default class ApplicationController extends Controller {
  @service declare intl: Services['intl'];
  @service declare router: Services['router'];

  get isEN(): boolean {
    return this.intl.primaryLocale === 'en-se';
  }

  get isPT(): boolean {
    return this.intl.primaryLocale === 'pt-br';
  }

  @action
  switchLocale(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const locale = target.value;
    this.intl.setLocale([locale, 'en-se']);
    this.router.refresh();
  }
}
