require "rubygems"
require "sequel"
require "mysql"

my = Sequel.mysql 'acrp', :user => 'acrp', :password => 'acrppass', :host => 'localhost'

workIDs     = my.query("select WorkID from pop_loans")
borrowerIDs = my.query("select BorrowerID from pop_loans")

