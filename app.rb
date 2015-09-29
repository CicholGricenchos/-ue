require 'fiber'
require './core'

Keyword.marshal_load
Character.marshal_load
Dialogue.marshal_load
puts c = Character.find(2)
p c.keyword
p c.keyword.select(&:meet_requirements?)

d = Drama.new do
  p 1
  p 2
end

p Dialogue[]