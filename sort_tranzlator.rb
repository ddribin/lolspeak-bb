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

tranzlator.keys.sort.each do |key|
  value = tranzlator[key]
  key = yaml_quote(key)
  value = yaml_quote(value)
  puts "#{key}: #{value}"
end
