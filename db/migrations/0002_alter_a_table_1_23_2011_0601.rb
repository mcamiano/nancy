# a migration to alter tables
migration "Remove add slug_client to foos" do
  database.alter_table :foos do
    add_column :slug_client, String
  end
end

