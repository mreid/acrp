ACRP Results
============

This is a list of things tried, the results and some analysis.

Simple Linear PCA
-----------------
The files `plots/works-linPCA-colLibrary.*` give a PDF plot of a linear PCA 
applied to works, interpreted as (binary valued) vectors of borrowers, with at 
least 20 loans. The points are coloured by library.

The plot shows a strong clustering by library. This makes sense since the books
available at a library limit what can be read by members of that library.

Restriction to a Single Library
-------------------------------
The SQL query:
    
    select LibraryID, count(WorkID) as Count 
    from pop_loans group by LibraryID;

results in the following table:

     LibraryID   Count
    ----------   -----
    -468206372    3297
    -414404825   14594
             2   20253
             4    5583
    1108618849    2672
    1118369451   14844

showing that the library with ID `2` has the largest number (20253) of loans 
with at least 20 borrowers.

Here are the library names:

    mysql> select ReadLibraryID, Name from tblreadlibrary;
    +---------------+------------------------------------------+
    | ReadLibraryID | Name                                     |
    +---------------+------------------------------------------+
    |             2 | Lambton Miners' and Mechanics' Institute | 
    |             3 | Newcastle School of Arts                 | 
    |             4 | Collie Miners Institute                  | 
    |    1101088136 | Victoria Mill School of Arts             | 
    |    -414404825 | South Australian Institute               | 
    |    1108618849 | Maitland Institute                       | 
    |     850495377 | Bundaberg School of Arts                 | 
    |    -468206372 | Rosedale Mechanics' Institute            | 
    |    1118369451 | Port Germein Institute                   | 
    |    1120100093 | Burra Institute                          | 
    |    1131595930 | Berwick Mechanics' Institute             | 
    +---------------+------------------------------------------+

