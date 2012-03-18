# balance_sheet_calculation_spec.rb

require 'spec_helper'

describe FinModeling::CashFlowStatementCalculation  do
  before(:all) do
    google_2011_annual_rpt = "http://www.sec.gov/Archives/edgar/data/1288776/000119312512025336/0001193125-12-025336-index.htm"
    filing = FinModeling::AnnualReportFiling.download(google_2011_annual_rpt)
    @cash_flow_stmt = filing.cash_flow_statement
    @period = @cash_flow_stmt.periods.last
  end

  describe "cash_change_calculation" do
    it "returns an CashChangeCalculation" do
      @cash_flow_stmt.cash_change_calculation.should be_an_instance_of FinModeling::CashChangeCalculation
    end
    it "returns the root node of the cash change calculation" do
      @cash_flow_stmt.cash_change_calculation.label.downcase.should match /^cash/
    end
  end

  describe "is_valid?" do
    it "returns true if free cash flow == financing flows" do
      flows_are_balanced = (   @cash_flow_stmt.reformulated(@period).free_cash_flow.total == 
                            -1*@cash_flow_stmt.reformulated(@period).financing_flows.total)
      @cash_flow_stmt.is_valid?.should == flows_are_balanced
    end
  end

  describe "reformulated" do
    it "takes a period and returns a ReformulatedCashFlowStatement" do
      @cash_flow_stmt.reformulated(@period).should be_an_instance_of FinModeling::ReformulatedCashFlowStatement
    end
  end

  describe "write_constructor" do
    before(:all) do
      file_name = "/tmp/finmodeling-cash_flow_stmt.rb"
      item_name = "@cfs"
      file = File.open(file_name, "w")
      @cash_flow_stmt.write_constructor(file, item_name)
      file.close

      eval(File.read(file_name))

      @loaded_cfs = eval(item_name)
    end

    it "writes itself to a file, and when reloaded, has the same periods" do
      expected_periods = @cash_flow_stmt.periods.map{|x| x.to_pretty_s}.join(',')
      @loaded_cfs.periods.map{|x| x.to_pretty_s}.join(',').should == expected_periods
    end
    it "writes itself to a file, and when reloaded, has the same change in cash" do
      period = @cash_flow_stmt.periods.last
      expected_cash_change = @cash_flow_stmt.cash_change_calculation.summary(:period=>period).total
      @loaded_cfs.cash_change_calculation.summary(:period=>period).total.should be_within(1.0).of(expected_cash_change)
    end
  end

end
