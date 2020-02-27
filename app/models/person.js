import Model, { attr, belongsTo } from "@ember-data/model";

export default class PersonModel extends Model {
  @attr("string") name;
  @attr("string") label;
  @attr("string") email;
  @attr("string") picture;
  @attr("string") phone;
  @attr("string") website;
  @attr("string") summary;
  @belongsTo("location") location;
  @belongsTo("resume") resume;
}
