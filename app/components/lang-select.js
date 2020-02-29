import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class LangSelectComponent extends Component {
  @service i18n;

  @action
  changeLocale(context) {
    this.i18n.locale = context.target.value;
  }
}
