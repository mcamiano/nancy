class Foos < Sequel::Model
  many_to_many :bars, :join_table=>:foos_bars # , :left_key=>:artistid, :right_key=>:albumid,
end

class Bar < Sequel::Model
  one_to_many :foos
end


__END__
# Associations
# see http://sequel.rubyforge.org/rdoc/files/doc/association_basics_rdoc.html
many_to_one   :  base table of model has foreign key to primary key in associated table
one_to_many   :  base table of model has primary key pointed to by associated table foreign key
one_to_one    :  like one to many , base table has primary get pointed to by associated table foreign key
many_to_many  :  uses join table { base_table_id, associated_table_id }, uses plural forms

# models just work ...
Foo.filter(:baz => 42).each { |foo| puts(foo.bar.name) }

# access the database within the context of an HTTP request
get '/foos/:id' do
  @foo = database[:foos].filter(:id => params[:id]).first
  erb :foos
end

# or, using the model
delete '/foos/:id' do
  @foo = Foo[params[:id]]
  @foo.delete
end


