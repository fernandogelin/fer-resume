import Model, { attr, belongsTo } from "@ember-data/model";

export default class LocationModel extends Model {
  @attr("string") address;
  @attr("string") city;
  @attr("string") postalCode;
  @attr("string") countryCode;
  @attr("string") region;
  @belongsTo("person") person;
  @belongsTo("resume") resume;
}
