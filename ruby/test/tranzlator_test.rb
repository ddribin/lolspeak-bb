$KCODE = "UTF-8"

require 'lolspeak'
require 'rexml/document'
require 'test/unit'

class TranzlatorTest < Test::Unit::TestCase
  def new_tranzlator
    data_dir = File.join(File.dirname(__FILE__), "data")
    yaml = File.join(data_dir, "tranzlator.yml")
    return LOLspeak::Tranzlator.from_file(yaml)
  end
  
  def test_creation
    tranzlator = LOLspeak::Tranzlator.new(nil)
    assert_not_nil tranzlator
  end
  
  def test_translate_word
    t = new_tranzlator
    assert_equal "cheezeburger", t.translate_word("cheeseburger")
    assert_equal "oh hai", t.translate_word("hi")
  end
  
  def test_translate_word_with_filter
    t = new_tranzlator
    assert_equal "OH HAI", t.translate_word("hi") {|w| w.upcase}
  end
  
  def test_translate_missing_word
    t = new_tranzlator
    assert_equal "eat", t.translate_word("eat")
  end
  
  def test_translate_missing_word_with_filter
    t = new_tranzlator
    assert_equal "EAT", t.translate_word("eat") {|w| w.upcase}
  end
  
  def test_downcase
    t = new_tranzlator
    assert_equal "oh hai", t.translate_word("Hi")
  end
  
  def test_downcase_missing
    t = new_tranzlator
    assert_equal "eat", t.translate_word("Eat")
  end
  
  def test_tranzlate_ascii_apostrophe
    t = new_tranzlator
    assert_equal "me", t.translate_word("I'm")
  end
  
  def test_tranzlate_unicode_apostrophe
    t = new_tranzlator
    assert_equal "me", t.translate_word("I’m")
  end
  
  def test_tranzlate_ascii_apostrophe_missing
    t = new_tranzlator
    assert_equal "it's", t.translate_word("it's")
  end
  
  def test_tranzlate_unicode_apostrophe_missing
    t = new_tranzlator
    assert_equal "it’s", t.translate_word("it’s")
  end
  
  def test_tranzlate_with_nonalpanum
    t = new_tranzlator
    assert_equal "f&#^bar", t.translate_word("foobar")
  end
  
  def test_translate_before_apostrophe
    t = new_tranzlator
    assert_equal "kitteh's", t.translate_word("cat's")
    assert_equal "kitteh’s", t.translate_word("cat’s")
  end

  def test_tranzlate_words
    t = new_tranzlator
    assert_equal "oh hai, me kitteh!  ur eating it’s cheezeburger",
      t.translate_words("Hi, I'm a cat!  Your eating it’s cheeseburger")
  end

  def test_tranzlate_words_with_filter
    t = new_tranzlator
    assert_equal "OH HAI, ME KITTEH!",
      t.translate_words("Hi, I'm a cat!") { |w| w.upcase }
  end
  
  def test_tranzlate_xml_string
    t = new_tranzlator
    xml = <<-XML
    <cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
    XML
    expected = <<-EXPECTED
    <cat cheeseburger='hi'>kitteh <b>cheezeburger</b> oh hai</cat>
    EXPECTED
    
    assert_equal expected, t.translate_xml_string(xml)
  end
  
  def test_tranzlate_xml_string_with_ampersand
    t = new_tranzlator
    assert_equal "<b>&nbsp;oh hai</b>",
      t.translate_xml_string("<b>&nbsp;hi</b>")
  end
  
  def test_tranzlate_xml_string_escape
    t = new_tranzlator
    assert_equal "<b>f&amp;#^bar</b>",
      t.translate_xml_string("<b>foobar</b>")
  end
  
  def test_tranzlate_xml_string_normalize
    t = new_tranzlator
    assert_equal "<b>me</b>",
      t.translate_xml_string("<b>I&#8217;m</b>")
  end
  
  def test_tranzlate_xml_string_with_filter
    t = new_tranzlator
    assert_equal "<b>OH HAI&NBSP;EAT</b>",
      t.translate_xml_string("<b>hi&nbsp;eat</b>") { |w| w.upcase }
  end
  
  def test_string_to_lolspeak
    LOLspeak.default_tranzlator = new_tranzlator
    assert_equal "oh hai, me eating it’s cheezeburger",
      "Hi, I'm eating it’s cheeseburger".to_lolspeak
  end
  
  def test_string_xml_to_lolspeak
    LOLspeak.default_tranzlator = new_tranzlator
    assert_equal "<b>oh hai kitteh</b>",
      "<b>hi cat</b>".xml_to_lolspeak
  end
  
  def test_string_xml_to_lolspeak_with_filter
    LOLspeak.default_tranzlator = new_tranzlator
    assert_equal "<b>OH HAI KITTEH</b>",
      "<b>hi cat</b>".xml_to_lolspeak { |w| w.upcase}
  end
  
  def test_string_to_lolspeak_with_filter
    LOLspeak.default_tranzlator = new_tranzlator
    assert_equal "OH HAI, ME EATING IT’S CHEEZEBURGER",
      "Hi, I'm eating it’s cheeseburger".to_lolspeak { |w| w.upcase }
  end
  
  def test_xml_element_recursive_to_lolspeak
    LOLspeak.default_tranzlator = new_tranzlator
    xml = <<-XML
    <cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
    XML
    document = REXML::Document.new xml

    expected = <<-EXPECTED
    <cat cheeseburger='hi'>cat <b>cheezeburger</b> hi</cat>
    EXPECTED
    document.root.to_lolspeak_recursive!
    assert_equal expected, document.to_s
  end
  
  def test_xml_element_to_lolspeak
    LOLspeak.default_tranzlator = new_tranzlator
    xml = <<-XML
    <cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
    XML
    document = REXML::Document.new xml

    expected = <<-EXPECTED
    <cat cheeseburger='hi'>kitteh <b>cheeseburger</b> oh hai</cat>
    EXPECTED
    document.root.to_lolspeak!
    assert_equal expected, document.to_s
  end
  
  def test_xml_element_to_lolspeak_with_filter
    LOLspeak.default_tranzlator = new_tranzlator
    xml = <<-XML
    <cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
    XML
    document = REXML::Document.new xml

    expected = <<-EXPECTED
    <cat cheeseburger='hi'>KITTEH <b>cheeseburger</b> OH HAI</cat>
    EXPECTED
    document.root.to_lolspeak! { |w| w.upcase }
    assert_equal expected, document.to_s
  end
  
  def test_xml_element_to_lolspeak_recursive
    LOLspeak.default_tranzlator = new_tranzlator
    xml = <<-XML
<cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
XML
    document = REXML::Document.new xml

    expected = <<-EXPECTED
<cat cheeseburger='hi'>kitteh <b>cheezeburger</b> oh hai</cat>
EXPECTED
    document.to_lolspeak_recursive!
    assert_equal expected, document.to_s
  end
  
  def test_xml_element_to_lolspeak_recursive_with_filter
    LOLspeak.default_tranzlator = new_tranzlator
    xml = <<-XML
<cat cheeseburger='hi'>cat <b>cheeseburger</b> hi</cat>
XML
    document = REXML::Document.new xml

    expected = <<-EXPECTED
<cat cheeseburger='hi'>KITTEH <b>CHEEZEBURGER</b> OH HAI</cat>
EXPECTED
    document.to_lolspeak_recursive! { |w| w.upcase }
    assert_equal expected, document.to_s
  end
  
  def test_default_tranzlator
    LOLspeak.default_tranzlator = nil
    assert_not_nil LOLspeak.default_tranzlator
  end
  
  def test_trace
    t = new_tranzlator
    t.trace = true
    t.translate_words("hi good cat")
    expected = {"hi" => "oh hai", "cat" => "kitteh"}
    assert_equal expected, t.traced_words
    
    t.clear_traced_words
    expected = {}
    assert_equal expected, t.traced_words
  end
  
  def test_heuristics
    t = new_tranzlator
    t.try_heuristics = true
    assert_equal "the mothr of invenshun fotograf humorous foo's",
      t.translate_words("the mother of invention photograph humorous foo's")

    expected = {"mother" => "mothr", "invention" => "invenshun",
      "photograph" => "fotograf"}
    assert_equal expected, t.translated_heuristics
    
    expected = {}
    t.clear_translated_heuristics
    assert_equal expected, t.translated_heuristics
  end
  
  def test_heuristics_exclude
    t = new_tranzlator
    t.try_heuristics = true
    t.heuristics_exclude = Set.new ['invention']
    assert_equal "the mothr of invention",
      t.translate_words("the mother of invention")

    expected = {"mother" => "mothr"}
    assert_equal expected, t.translated_heuristics
    
    expected = {}
    t.clear_translated_heuristics
    assert_equal expected, t.translated_heuristics
  end
end
