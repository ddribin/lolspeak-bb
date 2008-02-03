#!/usr/bin/ruby

$KCODE = 'UTF8'

require 'yaml'
require 'set'

tranzlator = YAML::load_file('tranzlator.yml')

def yaml_quote(string)
  quote = false
  booleans = Set.new ['yes', 'true', 'no', 'false']

  if string !~ /^[a-zA-Z]+$/
    quote = true
  elsif booleans.member?(string)
    quote = true
  end

  if quote
    return "\"#{string}\""
  else
    return string
  end
end

output = STDOUT
if ARGV.length == 1
  output = File.open(ARGV[0], 'w')
end

tranzlator.keys.sort.each do |key|
  value = tranzlator[key]
  key = yaml_quote(key)
  value = yaml_quote(value)
  output.puts "#{key}: #{value}"
end
