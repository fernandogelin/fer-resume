import Model, { attr, belongsTo } from "@ember-data/model";

export default class InterestModel extends Model {
  @attr() name;
  @attr() keywords;
  @belongsTo("resume") resume;
}
