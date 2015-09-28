require 'csv'
require './core'

def convert model
  c = CSV.read("#{model.name}.csv")
  head = c.shift
  head.map!(&:to_sym)
  c.map! do |v|
    v.map!{|x| x ||= ""; Integer x rescue x.force_encoding('utf-8')}
    Hash[head.zip(v)]
  end
  model.load_from_hash c
  model.marshal_dump
end

convert Character
convert Keyword
convert Dialogue