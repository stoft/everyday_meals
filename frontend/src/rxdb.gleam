import gleam/dynamic
import gleam/javascript/promise

pub opaque type Database

pub opaque type Collection

pub opaque type Document

@external(javascript, "./rxdb.js", "createDatabase")
pub fn create_database(name: String) -> promise.Promise(Database)

@external(javascript, "./rxdb.js", "createCollection")
pub fn create_collection(
  db: Database,
  name: String,
  schema: String,
) -> promise.Promise(Collection)

@external(javascript, "./rxdb.js", "upsert")
pub fn upsert(
  collection: Collection,
  doc: String,
) -> promise.Promise(dynamic.Dynamic)

@external(javascript, "./rxdb.js", "findOne")
pub fn find_one(
  collection: Collection,
  id: String,
) -> promise.Promise(dynamic.Dynamic)

@external(javascript, "./rxdb.js", "deleteDatabase")
pub fn delete_database(name: String) -> promise.Promise(Nil)
