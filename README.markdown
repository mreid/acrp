ACRP Notes
==========

Methodology
-----------

A simple first question that can be asked of the data is whether there exist
pairs of books (A,B) such that both A and B alone have a relatively large
number of readers but there are few readers which have read both A and B. Pairs
of this type can be further analysed to see whether certain books predict the
reading of A or B and whether reading is clustered that can be understood 
via reader's occupation, genre, gender, etc.

Set up
------
Several tables are created during analysis so as to speed things up. Once the
original ACRP database is loaded, run `split_pairs.sql` to build the extra
tables required before running `analysis.sql`.

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
