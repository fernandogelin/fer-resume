import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class LangSelectComponent extends Component {
  @service i18n;
  @service router;

  @action
  changeLocale(context) {
    let newLocale = context.target.value;
    this.i18n.locale = newLocale;
    if (newLocale === "pt-br") {
      this.router.transitionTo("resume.pt");
    } else {
      this.router.transitionTo("resume.en");
    }
  }
}
