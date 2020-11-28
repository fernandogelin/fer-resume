import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

export default class DateComponent extends Component {
  @service intl;
  get start() {
    const start = this.intl.formatDate(this.args.startDate)
    return start
  }
  get end() {
    if (this.args.endDate) {
      const end = this.intl.formatDate(this.args.endDate)
      return end
    } else {
      return "present";
    }
  }
}
