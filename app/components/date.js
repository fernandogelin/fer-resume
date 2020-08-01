import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { translationMacro as t } from "ember-i18next";

const options = {
  year: "numeric",
  month: "long"
};

export default class DateComponent extends Component {
  @service i18n;
  get start() {
    return this.args.startDate.toLocaleDateString(this.i18n.locale, options);
  }
  get end() {
    if (this.args.endDate) {
      return this.args.endDate.toLocaleDateString(this.i18n.locale, options);
    } else {
      return "present";
    }
  }
}
