import Model, { attr, belongsTo } from "@ember-data/model";

export default class SkillModel extends Model {
  @attr("string") name;
  @attr("string") level;
  @attr() keywords;
  @belongsTo("resume")
  resume;
}
