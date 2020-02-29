import Model, { attr, belongsTo } from "@ember-data/model";

export default class ProfileModel extends Model {
  @attr("string") network;
  @attr("string") username;
  @attr("string") url;
  @belongsTo("person") person;
}
