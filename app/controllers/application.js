import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

export default class ApplicationController extends Controller {
  @service intl

  get isEN() {
    return this.intl.get('primaryLocale') === 'en-se';
  }

  get isPT() {
    return this.intl.get('primaryLocale') === 'pt-br';
  }
}
