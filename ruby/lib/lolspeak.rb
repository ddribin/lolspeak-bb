$KCODE = "UTF-8"

require 'yaml'
require 'rexml/document'
require 'cgi'

module LOLspeak
  VERSION = "1.0.0"
  
  class Tranzlator
    attr_accessor :trace, :try_heuristics
    attr_reader :traced_words, :translated_heuristics
    
    class << Tranzlator
      def from_file(file)
        dictionary = YAML::load_file(file)
        return Tranzlator.new(dictionary)
      end
    end
    
    def initialize(dictionary)
      @dictionary = dictionary
      @traced_words = {}
      @try_heuristics = false
      @translated_heuristics = {}
    end

    def translate_word(word, &filter)
      word = word.downcase
      lol_word = @dictionary[word]
      if lol_word.nil?
        lol_word = @dictionary[word.gsub("’", "'")]
      end
      
      if lol_word.nil? and word.match(/(.*)([\’\']\w+)$/)
        prefix, suffix = $1, $2
        lol_word = @dictionary[prefix]
        lol_word += suffix if !lol_word.nil?
      end
      
      if lol_word.nil? and @try_heuristics
        if (word =~ /(.*)tion(s?)$/)
          lol_word = "#{$1}shun#{$2}"
        elsif (word =~ /(.*)ed$/)
          lol_word = "#{$1}d"
        elsif (word =~ /(.*)ing$/)
          lol_word = "#{$1}in"
        elsif (word =~ /(.*)ss$/)
          lol_word = "#{$1}s"
        elsif (word =~ /(.*)er$/)
          lol_word = "#{$1}r"
        elsif (word =~ /^([0-9A-Za-z_]+)s$/)
          lol_word = "#{$1}z"
        end
        if !lol_word.nil?
          @translated_heuristics[word] = lol_word
        end
      end

      if lol_word.nil?
        lol_word = word
      else
        @traced_words[word] = lol_word
      end
      
      if !filter.nil?
        lol_word = filter.call(lol_word)
      end

      return lol_word
    end
    
    def clear_traced_words
      @traced_words = {}
    end
    
    def clear_translated_heuristics
      @translated_heuristics = {}
    end
    
    def translate_words(words, &filter)
      lol_words = words.gsub(/(\w[\w’\']*)(\s*)/) do
        word, space = $1, $2
        lol_word = translate_word(word, &filter)

        # Stick the space back on, as long is it's not empty
        lol_word += space if lol_word != ""
        lol_word
      end
      return lol_words
    end
  
    def translate_xml_element!(xml_element, &filter)
      xml_element.texts.each do |text|
        string = text.to_s
        string = self.translate_words(string) do |w|
          w = CGI.escapeHTML(w)
          w = filter.call(w) if !filter.nil?
          w
        end
        new_text = REXML::Text.new(string, true, nil, true)
        text.replace_with(new_text)
      end
    end

    def translate_xml_element_recursive!(xml_element, &filter)
      xml_element.each_recursive { |e| translate_xml_element!(e, &filter) }
    end
  
    def translate_xml_string(xml_string, &filter)
      xml_doc = REXML::Document.new xml_string
      translate_xml_element_recursive!(xml_doc, &filter)
      return xml_doc.to_s
    end
  end

  class << self
    @@default_tranzlator = nil
    def default_tranzlator=(new_tranzlator)
      return @@default_tranzlator = new_tranzlator
    end

    def default_tranzlator
      if @@default_tranzlator.nil?
        default_file = File.join(File.dirname(__FILE__), "lolspeak", "tranzlator.yml")
        @@default_tranzlator = Tranzlator.from_file(default_file)
      end
      return @@default_tranzlator
    end
  end
end

class String
  def to_lolspeak(&filter)
    return LOLspeak::default_tranzlator.translate_words(self, &filter)
  end
  
  def xml_to_lolspeak(&filter)
    return LOLspeak::default_tranzlator.translate_xml_string(self, &filter)
  end
end

class REXML::Element
  def to_lolspeak!(&filter)
    LOLspeak::default_tranzlator.translate_xml_element!(self, &filter)
  end
  
  def to_lolspeak_recursive!(&filter)
    t = LOLspeak::default_tranzlator
    t.translate_xml_element_recursive!(self, &filter)
  end
end

