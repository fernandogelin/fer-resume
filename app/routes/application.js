import Route from "@ember/routing/route";
import I18nMixin from "ember-i18next/mixins/i18n";
import LngDetector from "i18next-browser-languagedetector";

export default class ApplicationRoute extends Route.extend(I18nMixin) {
  async beforeModel() {
    super.beforeModel(...arguments);
    await this.i18n.i18next.use(LngDetector);
    return this.i18n.initLibraryAsync();
  }

  model() {
    return this.store.findRecord("gist", "fbc7c5a8630ee55274ec7ee89f62dd5f", {
      include: "resume"
    });
  }
}
