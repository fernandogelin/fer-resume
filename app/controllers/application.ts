import Controller from '@ember/controller';
import { type Registry as Services, service } from '@ember/service';

export default class ApplicationController extends Controller {
  @service declare intl: Services['intl'];

  get isEN(): boolean {
    return this.intl.primaryLocale === 'en-se';
  }

  get isPT(): boolean {
    return this.intl.primaryLocale === 'pt-br';
  }
}
