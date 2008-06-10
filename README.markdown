ACRP Notes
==========
This project contains the analysis of data from the Australian Common
Reader Project in the form of snippets of R and SQL code as well as some 
resulting graphs and tables.

Importantly, the actual data used in this analysis is *NOT* included in this
project as I do not have the rights to redistribute it. The references to 
SQL databases and tables are for a local copy of the MySQL database I was given 
access to by the ACRP.

The rest of this file is some notes I made for myself while learning about
the database and analysing it.

Database Structure
------------------
The files `*_schema.txt` in the `db` directory are dumps of the MySQL database
by the query in the `describe.sh` shell script.

I turned the important parts of these schema into a PDF file 
-- `db/table.pdf` -- using OmniGraffle 5. The `.graffle` file is also 
available.

Set up
------
Several tables are created during analysis so as to speed things up. Once the
original ACRP database is loaded, run `setup.sql` to build the extra
tables required before running and of the R scripts for analysis.

Results
-------
The file `RESULTS.markdown` contains some useful counts and IDs collected
for reference as well as some notes on some early plots.

Seminar May 2008
----------------
The directory `seminarMay08` contains R analysis scripts and the resulting
PDF plots used in the seminar Julieanne gave to her faculty in May 2008. 

Notice that as I learned more about RMySQL I began moving more and more of the
database-related code into R in an effort to make the R scripts completely
self-contained.

Configuration
-------------
By default, the SQL mode in TextMate expects the file `/tmp/mysql.sock` to
exist. The installation of MySQL I'm using puts this file in `/opt/local/...`.
To work around this I use the following command:

    $ ln -s /opt/local/var/run/mysql5/mysqld.sock /tmp/mysql.sock

TextMate SQL View Gotcha
------------------------
By default, the SQL mode in TextMate will add a "LIMIT 10" statement to the
end of queries in the editor that are run using Ctrl-Shift-Q. This is fine for
viewing the head of what would otherwise be a large number of rows, but very
bad if you are trying to create a view since the resulting view will only 
contain 10 rows.
