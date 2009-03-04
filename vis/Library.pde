import java.util.ArrayList;

// Loads library information from a CSV file of the form
//     LibraryID, Library Name, Number of Works in Library
ArrayList loadLibraries(String filename) {
  ArrayList libraries = new ArrayList();
  
  CSVReader reader = new CSVReader(new InputStreamReader(openStream(filename)));
    
  try {
    reader.readNext();    // Skip header

    String[] row;
      
    while( (row = reader.readNext()) != null) {
      Library lib = new Library();
      lib.id = Integer.parseInt(row[0]);
      lib.name = row[1];
      lib.size = Integer.parseInt(row[2]);
        
      libraries.add(lib);
    }
  } catch(IOException ioe) {
    println("Badness: " + ioe.getMessage()); 
  }
  
  return libraries;
}

// Loads the Book/Library correspondances from the given file.
// The `libraries` argument is assumed to be the result from `loadLibraries`.

void loadLibraryWorks(ArrayList libraries, String filename) {
  CSVReader reader = new CSVReader(new InputStreamReader(openStream(filename)));
    
  try {
    reader.readNext();    // Skip header

    String[] row;
      
    while( (row = reader.readNext()) != null) {
      int libId = Integer.parseInt(row[0]);
      int workId = Integer.parseInt(row[1]);

      Book book = (Book) graph.get(workId);
      if(book == null) { 
        println("Book with workId = " + workId + " is null"); 
      } else {
        for(int i = 0; i < libraries.size(); i++) {
          Library lib = (Library) libraries.get(i);
          if(lib.id == libId) { 
            lib.books.add(book);
            book.libraries.add(lib);
          }
        }      
     }
    }
  } catch(IOException ioe) {
    println("Badness: " + ioe.getMessage()); 
  }
  
}

class Library {
    
  long id;
  String name;
  int size;
  ArrayList books = new ArrayList();
  
}
