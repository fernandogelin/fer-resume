import JSONSerializer from "@ember-data/serializer/json";
import DS from "ember-data";

export default class PersonSerializer extends JSONSerializer.extend(
  DS.EmbeddedRecordsMixin
) {
  attrs = {
    location: { embedded: "always" },
    profiles: { embedded: "always" }
  };

  normalize(type, hash) {
    hash.profiles.map(profile => (profile.id = profile.network.toLowerCase()));
    hash.location.id = "home";
    return super.normalize(...arguments);
  }
}
