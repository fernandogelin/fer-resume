import JSONSerializer from "@ember-data/serializer/json";
import DS from "ember-data";

export default class PersonSerializer extends JSONSerializer.extend(
  DS.EmbeddedRecordsMixin
) {
  attrs = {
    location: { embedded: "always" }
  };

  normalize(type, hash) {
    hash.location.id = "home";
    return super.normalize(...arguments);
  }
}
