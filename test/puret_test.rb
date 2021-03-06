require 'test_helper'

class PuretTest < ActiveSupport::TestCase
  def setup
    setup_db
    I18n.locale = I18n.default_locale = :en
    Post.create(:title => 'English title')
  end

  def teardown
    teardown_db
  end

  test "database setup" do
    assert_equal 1, Post.count
  end
 
  test "allow translation" do
    I18n.locale = :de
    Post.first.update_attribute :title, 'Deutscher Titel'
    assert_equal 'Deutscher Titel', Post.first.title
    I18n.locale = :en
    assert_equal 'English title', Post.first.title
  end
 
  test "assert fallback to default locale" do
    post = Post.first
    I18n.locale = :sv
    post.title = 'Svensk titel'
    I18n.locale = :en
    assert_equal 'English title', post.title
    I18n.locale = :de
    assert_equal 'English title', post.title
  end
 
  test "assert fallback to saved default locale defined on instance" do
    post = Post.first
    def post.default_locale() :sv; end
    assert_equal :sv, post.puret_default_locale
    I18n.locale = :sv
    post.title = 'Svensk titel'
    post.save!
    I18n.locale = :en
    assert_equal 'English title', post.title
    I18n.locale = :de
    assert_equal 'Svensk titel', post.title
  end
 
  test "assert fallback to saved default locale defined on class level" do
    post = Post.first
    def Post.default_locale() :sv; end
    assert_equal :sv, post.puret_default_locale
    I18n.locale = :sv
    post.title = 'Svensk titel'
    post.save!
    I18n.locale = :en
    assert_equal 'English title', post.title
    I18n.locale = :de
    assert_equal 'Svensk titel', post.title
  end
 
  test "post has_many translations" do
    assert_equal PostTranslation, Post.first.translations.first.class
  end
 
  test "translations are deleted when parent is destroyed" do
    I18n.locale = :de
    Post.first.update_attribute :title, 'Deutscher Titel'
    assert_equal 2, PostTranslation.count
    
    Post.destroy_all
    assert_equal 0, PostTranslation.count
  end
  
  test 'validates_presence_of should work' do
    post = Post.new
    assert_equal false, post.valid?
    
    post.title = 'English title'
    assert_equal true, post.valid?
  end

  test 'temporary locale switch should not clear changes' do
    I18n.locale = :de
    post = Post.first
    post.text = 'Deutscher Text'
    assert !post.title.blank?
    assert_equal 'Deutscher Text', post.text
  end

  test 'temporary locale switch should work like expected' do
    post = Post.new
    post.title = 'English title'
    I18n.locale = :de
    post.title = 'Deutscher Titel'
    post.save
    assert_equal 'Deutscher Titel', post.title
    I18n.locale = :en
    assert_equal 'English title', post.title
  end

  test 'translation model should validate presence of model' do
    t = PostTranslation.new
    t.valid?
    assert_not_nil t.errors[:post]
  end

  test 'translation model should validate presence of locale' do
    t = PostTranslation.new
    t.valid?
    assert_not_nil t.errors[:locale]
  end

  test 'translation model should validate uniqueness of locale in model scope' do
    post = Post.first
    t1 = PostTranslation.new :post => post, :locale => "de"
    t1.save!
    t2 = PostTranslation.new :post => post, :locale => "de"
    assert_not_nil t2.errors[:locale]
  end

  test 'model should provide attribute_before_type_cast' do
    assert_equal Post.first.title, Post.first.title_before_type_cast
  end

  test 'should return all translations for nested forms' do
    post = Post.new
    post.title = 'English title'
    I18n.locale = :it
    post.title = 'Titolo italiano'
    post.save
    assert_equal post.all_translations.class, ActiveSupport::OrderedHash 
  end

  test 'should be able to run dynamic finder on translated attributes' do
    post = Post.new
    post.title = 'English title'
    I18n.locale = :it
    post.title = 'Titolo italiano'
    post.save

    assert_equal Post.find_by_title('Titolo italiano').class, Post
    I18n.locale = :en
    assert_operator Post.find_all_by_title('English title').count, :>=, 1
    
    assert_nil Post.find_by_title('bla')
    assert Post.find_all_by_title('bla'), []

  end
  
  test 'should be able to set and get attributes by spcecify locale translation' do
    post = Post.new
    post.title_en = 'Eng title'
    post.title_it = 'Tit ita'
    assert_equal post.title_en,  'Eng title'
    assert_equal post.title_it,  'Tit ita'
    post.save
    I18n.locale = :en
    p = Post.find_by_title('Eng title')

    assert_equal p.title_en,  'Eng title'
    assert_equal p.title_it,  'Tit ita'
  end

  test 'should return nil when a saved record does not have the corresponding locale' do
    post = Post.new
    post.title_en = 'Eng title'
    post.save
    p = Post.find_by_title('Eng title')
    assert_nil p.title_it
  end

end
