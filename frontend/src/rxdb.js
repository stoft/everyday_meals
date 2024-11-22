import { createRxDatabase, removeRxDatabase } from "rxdb";
import { getRxStorageDexie } from "rxdb/plugins/storage-dexie";

export function createDatabase(name) {
  return createRxDatabase({
    name,
    storage: getRxStorageDexie(),
  });
}

export function createCollection(db, name, schema) {
  return db
    .addCollections({
      [name]: {
        schema: JSON.parse(schema),
      },
    })
    .then((collections) => collections[name]);
}

export function upsert(collection, doc) {
  console.log(doc);
  const result = collection.upsert(JSON.parse(doc));
  console.log(result);
  return result;
}

export function findOne(collection, id) {
  return collection.findOne(id).exec();
}

export function deleteDatabase(name) {
  return removeRxDatabase(name);
}
