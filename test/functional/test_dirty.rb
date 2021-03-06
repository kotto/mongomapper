require 'test_helper'
require 'models'

class Dirtydest < Test::Unit::TestCase
  [MongoMapper::EmbeddedDocument, MongoMapper::Document].each do |klass|

    def empty_document(klass)
      if klass == MongoMapper::Document
        @document.new
      else
        Content.new(:comments => [Comment.new]).comments.first
      end
    end

  context "in #{klass}" do
    setup do
      if klass == MongoMapper::Document
        @document = Content
      else
        @document= Comment
      end
      Status.collection.remove
      Project.collection.remove
      Content.collection.remove
    end


    context "marking changes" do
      should "not happen if there are none" do
        doc = empty_document(klass)
        doc.phrase_changed?.should be_false
        doc.phrase_change.should be_nil
      end

      should "happen when change happens" do
        doc = empty_document(klass)
        doc.phrase = 'Golly Gee Willikers Batman'
        doc.phrase_changed?.should be_true
        doc.phrase_was.should be_nil
        doc.phrase_change.should == [nil, 'Golly Gee Willikers Batman']
      end

      should "happen when initializing" do
        doc = @document.new(:phrase => 'Foo')
        doc.changed?.should be_true
      end

      should "clear changes on save" do
        doc = empty_document(klass)
        doc.phrase = 'Golly Gee Willikers Batman'
        doc.phrase_changed?.should be_true
        doc.save
        doc.phrase_changed?.should_not be_true
        doc.phrase_change.should be_nil
      end

      should "clear changes on save!" do
        doc = empty_document(klass)
        doc.phrase = 'Golly Gee Willikers Batman'
        doc.phrase_changed?.should be_true
        doc.save!
        doc.phrase_changed?.should_not be_true
        doc.phrase_change.should be_nil
      end

      if klass == MongoMapper::Document
      should "not happen when loading from database" do
        doc = @document.create(:phrase => 'Foo')

        doc = doc.reload
        doc.changed?.should be_false
      end

      should "happen if changed after loading from database" do
        doc = @document.create(:phrase => 'Foo')

        doc = doc.reload
        doc.changed?.should be_false
        doc.phrase = 'Bar'
        doc.changed?.should be_true
      end
      end
    end

    context "blank new value and type integer" do
      should "not mark changes" do
        @document.key :age, Integer

        [nil, ''].each do |value|
          doc = empty_document(klass)
          doc.age = value
          doc.age_changed?.should be_false
          doc.age_change.should be_nil
        end
      end
    end

    context "blank new value and type float" do
      should "not mark changes" do
        @document.key :amount, Float

        [nil, ''].each do |value|
          doc = empty_document(klass)
          doc.amount = value
          doc.amount_changed?.should be_false
          doc.amount_change.should be_nil
        end
      end
    end

    context "changed?" do
      should "be true if key changed" do
        doc = empty_document(klass)
        doc.phrase = 'A penny saved is a penny earned.'
        doc.changed?.should be_true
      end

      should "be false if no keys changed" do
        empty_document(klass).changed?.should be_false
      end
    end

    context "changes" do
      should "be empty hash if no changes" do
        empty_document(klass).changes.should == {}
      end

      should "be hash of keys with values of changes if there are changes" do
        doc = empty_document(klass)
        doc.phrase = 'A penny saved is a penny earned.'
        doc.changes.should == {'phrase' => [nil, 'A penny saved is a penny earned.']}
      end
    end

    context "changed" do
      should "be empty array if no changes" do
        empty_document(klass).changed.should == []
      end

      should "be array of keys that have changed if there are changes" do
        doc = empty_document(klass)
        doc.phrase = 'A penny saved is a penny earned.'
        doc.changed.should == ['phrase']
      end
    end

    if klass == MongoMapper::Document
    context "will_change!" do
      should "mark changes" do
        doc = @document.create(:phrase => 'Foo')

        doc.phrase << 'bar'
        doc.phrase_changed?.should be_false

        doc.phrase_will_change!
        doc.phrase_changed?.should be_true
        doc.phrase_change.should == ['Foobar', 'Foobar']

        doc.phrase << '!'
        doc.phrase_changed?.should be_true
        doc.phrase_change.should == ['Foobar', 'Foobar!']
      end
    end

    context "changing a foreign key through association" do
      should "mark changes" do
        status = Status.create(:name => 'Foo')
        status.project = Project.create(:name => 'Bar')
        status.changed?.should be_true
        status.changed.should == %w(project_id)
      end
    end
    end
  end
  end
end
