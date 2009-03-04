import java.util.Hashtable;
import java.util.ArrayList;

/**
 * Represents the neighbourhood graph of books
 */
class Graph {
  Hashtable edges = new Hashtable();
  ArrayList books = new ArrayList();
  Hashtable idToBooks = new Hashtable();
  
  float xmin = Float.POSITIVE_INFINITY;
  float ymin = Float.POSITIVE_INFINITY; 
  float xmax = Float.NEGATIVE_INFINITY; 
  float ymax = Float.NEGATIVE_INFINITY;

  Book get(int workId) {
    return (Book) idToBooks.get(new Integer(workId)); 
  }

  void addEdge(Book from, Book to, int shared) {
    ArrayList edgeList;
    if(edges.containsKey(from)) {
      edgeList = (ArrayList) edges.get(from);
    } else {
      edgeList = new ArrayList();
      edges.put(from, edgeList);
    }
    edgeList.add(new Edge(to, shared));
  }
  
  void loadBooks(String filename) {
    CSVReader reader = new CSVReader(new InputStreamReader(openStream(filename)));

    try {
      reader.readNext(); 	// Skip column headers.
      String[] row;
      while ((row = reader.readNext()) != null) {
        Book book = new Book();
        book.id = Integer.parseInt(row[0]);
        book.title = row[1];
        book.author = row[2];
        book.year = row[3];
        book.readers = Integer.parseInt(row[4]);
        book.x = Float.parseFloat(row[5]);
        book.y = Float.parseFloat(row[6]);

        // Books are added in order read, which should be sorted by ID by
        // the R program that generated the file being read. 
        books.add(book);
        idToBooks.put(new Integer(book.id), book);

        xmin = min(xmin, book.x); ymin = min(ymin, book.y);
        xmax = max(xmax, book.x); ymax = max(ymax, book.y);
      }
    } catch (IOException ioe) {
      println("Badness: " + ioe.getMessage());
    }

    println("Books added: " + books.size());    
  }
  
  void loadEdges(String filename) {
    CSVReader reader = new CSVReader(new InputStreamReader(openStream(filename)));
    
    try {
      reader.readNext();    // Skip header

      String[] row;
      int rownum = 1;
      
      while( (row = reader.readNext()) != null) {
        int id = Integer.parseInt(row[0]);
        Book from = (Book) books.get(rownum-1);
        
        for(int colnum = 1 ; colnum < row.length; colnum++) {
          Book to = (Book) books.get(colnum-1);
          int shared = Integer.parseInt(row[colnum]);
          if(shared > 0) {
            addEdge(from, to, shared);
          }
        }
        
        rownum++;
      }
    } catch(IOException ioe) {
      println("Badness: " + ioe.getMessage()); 
    }
  }
}

/**
 * An edge contains a destination Book and the number representing the shared
 * borrowers.
 */
class Edge {
  Book to;
  int shared;
  
  Edge(Book to, int shared) {
    this.to = to;
    this.shared = shared; 
  }
}
