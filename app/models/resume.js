import Model, { attr, belongsTo, hasMany } from "@ember-data/model";

export default class ResumeModel extends Model {
  @attr("string") content;
  @belongsTo("gist") gist;
  @belongsTo("person") person;
  @hasMany("education") education;
  @hasMany("work") work;
  @hasMany("skill") skills;
  @hasMany("interest") interests;
  @hasMany("language") languages;
}
