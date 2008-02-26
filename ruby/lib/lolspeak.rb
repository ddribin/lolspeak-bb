$KCODE = "UTF-8"

require 'lolspeak/version'
require 'yaml'
require 'rexml/document'
require 'cgi'

# This module encapsulates the English to LOLspeak translator.
# See LOLspeak::Tranzlator for more information.
module LOLspeak
  # A class to perform English to LOLspeak translation based on a dictionary
  # of words.
  class Tranzlator
    # (bool -> false) Wether or not to record translations
    attr_accessor :trace
    # (bool -> false) If true, try heurstics when translating words.  If
    # false, only use the dictionary for translation.
    attr_accessor :try_heuristics
    # (Hash) Stores all translations, if trace is true.
    attr_reader :traced_words
    # (Hash) Stores all words translated via heuristics, if try_heuristics is
    # true.
    attr_reader :translated_heuristics
    
    class << Tranzlator
      # Creates a Tranzlator using a dictionary from a YAML file
      #
      # :call-seq:
      #   Tranzlator.from_file(file)        -> Tranzlator
      #
      def from_file(file)
        dictionary = YAML::load_file(file)
        return Tranzlator.new(dictionary)
      end
    end
    
    # Creates a Tranzlator from the given dictionary
    #
    # :call-seq:
    #   initialize(dictionary) -> Tranzlator
    #
    def initialize(dictionary)
      @dictionary = dictionary
      @traced_words = {}
      @try_heuristics = false
      @translated_heuristics = {}
    end

    # Translates a single word into LOLspeak. By default, the result is in all
    # lower case:
    #   
    #   translator.translate_word("Hi") -> "oh hai"
    #      
    # If a block is given the word may
    # be transformed.  You could use this to upper case or XML encode the
    # result.  This example upper cases the result:
    #
    #   translator.translate_word("hi") { |w| w.upcase } -> "OH HAI"
    #
    # If heuristics are off, then only words in the dictionary are translated.
    # If heuristics are on, then words not in the dictionary may be translated
    # using standard LOLspeak heuristics, such as "*tion" -> "*shun".
    #
    # :call-seq:
    #  translate_word(word)                       -> String
    #  translate_word(word) { |word| transform }  -> String
    #
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
    
    # Clears the trace word hash
    def clear_traced_words
      @traced_words = {}
    end
    
    # Clears the hash storing words translated by heuristics
    def clear_translated_heuristics
      @translated_heuristics = {}
    end
    
    # Translates all the words in a string. If a block is given, it is called
    # to transform each individual word.
    #
    # :call-seq:
    #  translate_words(words)                       -> String
    #  translate_words(words) { |word| transform }  -> String
    #
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
  
    # Translates the REXML::Text parts of a single REXML::Element. The element
    # is modified in place.
    #
    # If a block is given, it is called to transform each individual word. By
    # default, each word is XML escaped, so this transform applies on top of
    # that.
    #
    # :call-seq:
    #  translate_xml_element!(xml_element)
    #  translate_xml_element!(xml_element) { |word| transform }
    #
    def translate_xml_element!(xml_element, &filter)
      xml_element.texts.each do |text|
        string = REXML::Text::unnormalize(text.to_s)
        string = self.translate_words(string) do |w|
          w = REXML::Text::normalize(w)
          w = filter.call(w) if !filter.nil?
          w
        end
        new_text = REXML::Text.new(string, true, nil, true)
        text.replace_with(new_text)
      end
    end

    # Translates the REXML::Text parts of an REXML::Element and all child
    # elements. The elements are modified in place.
    #
    # If a block is given, it iscalled to transform each individual word. By
    # default, each word is XML escaped, so this transform applies on top of
    # that.
    #
    # :call-seq:
    #  translate_xml_element!(xml_element)
    #  translate_xml_element!(xml_element) { |word| transform }
    #
    def translate_xml_element_recursive!(xml_element, &filter)
      xml_element.each_recursive { |e| translate_xml_element!(e, &filter) }
    end
  
    # Translates the text parts of a well-formed XML string.  It parses the
    # string using REXML and then translates the root element using
    # translate_xml_element_recursive!.
    #
    # If a block is given, it is called to transform each individual word.
    #
    # :call-seq:
    #   translate_xml_string(xml_string)                      -> String
    #   translate_xml_string(xml_string) { |word| transform } -> String
    #
    def translate_xml_string(xml_string, &filter)
      xml_doc = REXML::Document.new xml_string
      translate_xml_element_recursive!(xml_doc, &filter)
      return xml_doc.to_s
    end
  end

  class << self
    @@default_tranzlator = nil
    
    # Sets the default Tranzlator to new_tranzlator
    #
    def default_tranzlator=(new_tranzlator)
      return @@default_tranzlator = new_tranzlator
    end

    # Returns the default Tranzlator.  On the first time it is called, it
    # creates a Translator using the built-in dictionary.
    #
    def default_tranzlator
      if @@default_tranzlator.nil?
        default_file = File.join(File.dirname(__FILE__), "lolspeak",
          "tranzlator.yml")
        @@default_tranzlator = Tranzlator.from_file(default_file)
      end
      return @@default_tranzlator
    end
  end
end

class String
  # Translates all the words in this string.  Calls Tranzlator.translate_words
  # on the receiver using the default Tranzlator.
  #
  #   "Hi cat".to_lospeak -> "oh hai kitteh"
  #
  # See also: LOLspeak.default_tranzlator
  #     
  # :call-seq:
  #   to_lolspeak                       -> String
  #   to_lolspeak { |word| transform }  -> String
  #
  def to_lolspeak(&filter)
    return LOLspeak::default_tranzlator.translate_words(self, &filter)
  end
  
  # Treats the string as XML and translates all the text in this string. Calls
  # Tranzlator.translate_xml_string on the receiver using the default
  # Tranzlator.
  #
  # See also: LOLspeak.default_tranzlator
  #
  # :call-seq:
  #   xml_to_lolspeak                       -> String
  #   xml_to_lolspeak { |word| transform }  -> String
  #
  def xml_to_lolspeak(&filter)
    return LOLspeak::default_tranzlator.translate_xml_string(self, &filter)
  end
end

module REXML # :nodoc:
  class Element
    
    # Translates each REXML::Text of this element.  Calls
    # Tranzlator.translate_xml_element! on the receiver using the default
    # tranzlator.
    #
    # See also: LOLspeak.default_tranzlator
    #
    # :call-seq:
    #   to_lolspeak!
    #   to_lolspeak! { |word| transform }
    #
    def to_lolspeak!(&filter)
      LOLspeak::default_tranzlator.translate_xml_element!(self, &filter)
    end
  
    # Translates each REXML::Text of this element and all child elements.
    # Calls Tranzlator.translate_xml_element_recusvie! on the receiver using
    # the default tranzlator.
    #
    # See also: LOLspeak.default_tranzlator
    #
    # :call-seq:
    #   to_lolspeak_recursive!
    #   to_lolspeak_recursive! { |word| transform }
    #
    def to_lolspeak_recursive!(&filter)
      t = LOLspeak::default_tranzlator
      t.translate_xml_element_recursive!(self, &filter)
    end
  end
end
