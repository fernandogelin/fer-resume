import Route from "@ember/routing/route";

export default class ResumeRoute extends Route {
  model() {
    return this.modelFor("application").get("resume");
  }
}
