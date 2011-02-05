# a migration to alter tables
migration "Remove baz and add bling to foos" do
  database.alter_table :foos do
    drop_column :baz
    add_column :bling, :float
  end
end

