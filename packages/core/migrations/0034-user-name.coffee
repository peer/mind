class NameMigration extends Document.AddGeneratedFieldsMigration
  name: "Adding name field"
  fields: ['name']

class NameSetMigration extends Document.AddOptionalFieldsMigration
  name: "Adding nameSet field"
  fields: ['nameSet']

User.addMigration new NameMigration()
User.addMigration new NameSetMigration()
