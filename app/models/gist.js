import Model, { attr, belongsTo } from "@ember-data/model";

export default class GistModel extends Model {
  @attr("string") url;
  @belongsTo("resume") resume;
}
