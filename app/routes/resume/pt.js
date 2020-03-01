import Route from "@ember/routing/route";

export default class ResumePtRoute extends Route {
  model() {
    return this.store.findRecord("gist", "da99c3da93c806d4d6319279c844ad72");
  }
}
