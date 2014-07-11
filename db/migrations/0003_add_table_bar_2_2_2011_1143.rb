# a migration to alter tables
migration "Add bar table" do
  database.create_table :bar do
    primary_key :id
    text :description
    integer :fuzzle, :default => 7

    foreign_key :foos_id, :foos
  end
end

