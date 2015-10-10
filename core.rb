#encoding: utf-8

class Character
  attr_accessor :id, :name, :keywords
  def initialize(raw_data)
    character = raw_data['Character']
    @id = character['id']
    @name = character['name']
    @keywords = character['keywords'].map{|k, v| Keyword.new k, v}
  end

  def keywords
    @keywords
  end
end

class Keyword
  attr_accessor :name, :dialogues
  def initialize name, dialogues
    @name = name
    @dialogues = dialogues.map{|data| Dialogue.new data }
  end
end

class Dialogue
  attr_accessor :requirement, :lines
  def initialize data
    @requirement = data['requirement']
    @lines = data['lines']
  end
end

require 'yaml'
require 'pp'

yml = <<EOF
Character:
  id: 123
  name: dare
  keywords:
    Greeting:
      - lines:
          - tetet

      - requirement: 2312312
        lines:
          - te
EOF

pp Character.new(YAML.load(yml))