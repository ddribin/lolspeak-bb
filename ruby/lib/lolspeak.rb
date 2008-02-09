require 'yaml'
require 'rexml/document'

module LOLSpeak
  class Tranzlator
    class << Tranzlator
      def from_file(file)
        dictionary = YAML::load_file(file)
        return Tranzlator.new(dictionary)
      end
    end
    
    def initialize(dictionary)
      @dictionary = dictionary
    end
    
    def translate_word(word)
      word = word.downcase
      lol_word = @dictionary[word]
      if lol_word.nil?
        lol_word = @dictionary[word.gsub("’", "'")]
      end
      if lol_word.nil?
        lol_word = word
      end
      return lol_word
    end
    
    def translate_words(words)
      lol_words = words.gsub(/(\w[\w’\']*)(\s*)/) do
        word, space = $1, $2
        lol_word = translate_word(word)

        # Stick the space back on, as long is it's not empty
        lol_word += space if lol_word != ""
        lol_word
      end
      return lol_words
    end
  
    def translate_xml_element(xml_element)
      xml_element.texts.each do |text|
        string = text.value
        string = self.translate_words(string)
        text.replace_with(REXML::Text.new(string))
      end
    end
  
    def translate_xml_string(xml_string)
      xml_doc = REXML::Document.new xml_string
      xml_doc.each_recursive { |e| translate_xml_element(e) }
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
  def to_lolspeak
    return LOLSpeak::default_tranzlator.translate_words(self)
  end
end
