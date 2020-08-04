import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

const options = {
  year: "numeric",
  month: "long"
};

export default class DateComponent extends Component {
  @service i18n;
  get start() {
    const start = new Date(this.args.startDate)
    return start.toLocaleDateString(this.i18n.locale, options);
  }
  get end() {
    if (this.args.endDate) {
      const end = new Date(this.args.endDate)
      return end.toLocaleDateString(this.i18n.locale, options);
    } else {
      return "present";
    }
  }
}
