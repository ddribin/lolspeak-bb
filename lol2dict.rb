#!/usr/bin/ruby

$KCODE = 'UTF8'

require 'yaml'

class Hash
  def to_apple_dictionary(io = STDOUT)
    io.puts '<?xml version="1.0" encoding="UTF-8"?>'
    io.puts '<d:dictionary xmlns="http://www.w3.org/1999/xhtml" xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng">'
    self.keys.sort.each do |key|
      value = self[key]
      io.puts <<ENTRY
<d:entry id="#{key}">
    <d:index d:value="#{key}" d:title="#{key}"/>
    <h1>#{key}</h1>
    <p>#{value}</p>
</d:entry>
ENTRY
    end
    io.puts '</d:dictionary>'
  end
end

tranzlator = YAML::load_file('tranzlator.yml')

tranzlator.to_apple_dictionary

