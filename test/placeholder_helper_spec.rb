require File.dirname(__FILE__) + '/../spec_helper'

describe PlaceholderHelper do
  
  include PlaceholderHelper
  
  describe '#placeholder' do
    it "should return a placeholder by default" do
      placeholder.should == %Q{<div class="placeholder">Er is niets om weer te geven.</div>}
    end
    
    it "should accept a custom message" do
      placeholder('bla').should == %Q{<div class="placeholder">bla</div>}
    end
    
    it "should accept a custom tag" do
      placeholder(nil, :tag => :span).should == %Q{<span class="placeholder">Er is niets om weer te geven.</span>}
    end
  end
  
  describe '#phf' do
    it "should return a string passed in" do
      phf('my string').should == 'my string'
    end
    
    it "should escape a string passed in" do
      self.should_receive(:h).with('my string').once.and_return('my string2')
      phf('my string').should == 'my string2'
    end
    
    it "should return a placeholder if the text is blank" do
      self.should_receive(:placeholder).with('Niet opgegeven', :tag => :span).once.and_return('placeholder')
      phf('').should == 'placeholder'
    end
    
    it "should return a placeholder if the text is nil" do
      self.should_receive(:placeholder).with('Niet opgegeven', :tag => :span).once.and_return('placeholder')
      phf(nil).should == 'placeholder'
    end
    
    it "should pass in custom message to #placeholder" do
      self.should_receive(:placeholder).with('custom message', :tag => :span).once.and_return('placeholder')
      phf(nil, 'custom message').should == 'placeholder'
    end
  end

  describe '#placeholder_unless' do
    it "should render the block when given TRUE" do
      self.should_receive(:capture).with(any_args).and_return('hoeaap')
      self.should_receive(:concat).with("hoeaap", anything)
      placeholder_unless(true) { 'hoeaap' }
    end
    
    it "should return a placeholder when given FALSE" do
      self.should_receive(:placeholder).with(no_args).and_return('bla')
      self.should_receive(:concat).with('bla', anything)
      placeholder_unless(false) { 'hoeaap' }
    end
    
    it "should customize the placeholder" do
      self.should_receive(:placeholder).with('bla', :span).and_return('bla')
      self.should_receive(:concat).with('bla', anything)
      placeholder_unless(false, 'bla', :span) { 'hoeaap' }
    end
  end
end