import Model, { attr, belongsTo } from "@ember-data/model";

export default class GistModel extends Model {
  @attr("string") url;
  @attr("string") locale;
  @belongsTo("resume") resume;
}
