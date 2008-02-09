require 'lolspeak'
require 'test/unit'

class TranzlatorTest < Test::Unit::TestCase
  def new_tranzlator
    data_dir = File.join(File.dirname(__FILE__), "data")
    yaml = File.join(data_dir, "tranzlator.yml")
    return LOLSpeak::Tranzlator.from_file(yaml)
  end
  
  def test_creation
    tranzlator = LOLSpeak::Tranzlator.new(nil)
    assert_not_nil tranzlator
  end
  
  def test_translate_word
    t = new_tranzlator
    assert_equal "cheezeburger", t.translate_word("cheeseburger")
    assert_equal "oh hai", t.translate_word("hi")
  end
  
  def test_translate_missing_word
    t = new_tranzlator
    assert_equal "eat", t.translate_word("eat")
  end
  
  def test_downcase
    t = new_tranzlator
    assert_equal "oh hai", t.translate_word("Hi")
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

  def test_tranzlate_words
    t = new_tranzlator
    assert_equal "oh hai, me kitteh!  ur eating it’s cheezeburger",
      t.translate_words("Hi, I'm a cat!  Your eating it’s cheeseburger")
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
  
  def test_string_to_lolspeak
    LOLSpeak.default_tranzlator = new_tranzlator
    assert_equal "oh hai, me eating it’s cheezeburger",
      "Hi, I'm eating it’s cheeseburger".to_lolspeak
  end
  
  def test_default_tranzlator
    LOLSpeak.default_tranzlator = nil
    assert_not_nil LOLSpeak.default_tranzlator
  end
end
