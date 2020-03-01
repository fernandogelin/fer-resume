import Route from "@ember/routing/route";

export default class ResumeEnRoute extends Route {
  model() {
    return this.store.findRecord("gist", "fbc7c5a8630ee55274ec7ee89f62dd5f");
  }
}
