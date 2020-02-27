import Model, { attr, belongsTo } from "@ember-data/model";

export default class LanguageModel extends Model {
  @attr() language;
  @attr() fluency;
  @belongsTo("resume") resume;
}
