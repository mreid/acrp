import processing.core.*; 
import processing.xml.*; 

import controlP5.*; 
import au.com.bytecode.opencsv.*; 
import au.com.bytecode.opencsv.bean.*; 
import java.io.*; 
import java.awt.Rectangle; 
import java.util.Hashtable; 
import java.util.ArrayList; 
import java.util.ArrayList; 
import java.util.Vector; 

import java.applet.*; 
import java.awt.*; 
import java.awt.image.*; 
import java.awt.event.*; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class vis extends PApplet {







String basedir = "eReaders2008";

public int readerThreshold = 0;
public float weightThreshold = 0.25f;
ArrayList active = new ArrayList();

Graph graph;
PlotView view;
Book selected;
Rectangle lasso;
ArrayList libraries;
Library currentLib;

ControlP5 controlP5;
ScrollList listLibs;
Textlabel labelTitle;
Textlabel labelAuthor;
Textfield textAuthor;
Textfield textTitle;
String authorQuery;
String titleQuery;

public void setup() {
  size(750,550, JAVA2D);
//  size(800,750, JAVA2D);
  
  noLoop();
//  frameRate(10);
  background(255);

  // Create the graph
  graph = new Graph();
  graph.loadBooks(basedir + "/coords.csv");
  graph.loadEdges(basedir + "/neighbours.csv");
  
  // Load the library information
  libraries = loadLibraries(basedir + "/libraries.csv");
  loadLibraryWorks(libraries, basedir + "/worklibs.csv");

  float vwidth = (graph.xmax - graph.xmin) * 1.05f;
  float vheight = (graph.ymax - graph.ymin) * 1.05f;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view = new PlotView(
    20,20,width-40,height-100,
    graph.xmin, graph.ymin, graph.xmin + vwidth, graph.ymin + vheight
  );

  view.setTitle("Books Arranged By Similarity Using t-SNE");
        
//  for(int i=0; i < graph.books.size(); i++) {
//    view.add((Drawable) graph.books.get(i)); 
//  }

  // Controls for thresholds
  controlP5 = new ControlP5(this);
  controlP5.addSlider("weightThreshold", 0.0f, 1.0f, 0.25f, width-220, height-30, 200, 20);
  controlP5.addTextlabel("sim", "Similarity", width-120, height-30);
  controlP5.addSlider("readerThreshold", 0, 100, 0, width-220, height-60, 200, 20);  
  controlP5.addTextlabel("read", "Borrowers", width-120, height-60);

  // Labels to display selected title and author
  labelTitle = controlP5.addTextlabel("title", "(No Selection)                                   ", 20, height-60);
  labelTitle.setColorValue(0);  
  labelAuthor = controlP5.addTextlabel("author", "                                   ", 20, height-40);
  labelAuthor.setColorValue(0);  


  // Scroll Box for Libraries
  ScrollList listLibs = controlP5.addScrollList("libs",width/2-120,30,240,120);
  
  listLibs.setLabel("Choose Libraries");
  listLibs.addItem("All Libraries",libraries.size()).setId(libraries.size());
  
  for(int i=0;i<libraries.size();i++) {
    Library lib = (Library) libraries.get(i);
    controlP5.Button b = listLibs.addItem(lib.name,i+1);
    b.setId(i);
  }
  listLibs.close();

  // Text Field for Author search
  textAuthor = controlP5.addTextfield("authorQuery", width/2 - 75, height-30, 150, 20);
  controlP5.addTextlabel("authorLabel", "Author", width/2 - 75, height-30);

  // Text Field for Title search
  textTitle = controlP5.addTextfield("titleQuery", width/2 - 75, height-60, 150, 20);
  controlP5.addTextlabel("titleLabel", "Title", width/2 - 75, height-60);

  smooth();  
}

public ArrayList getBooks() {
  ArrayList books = graph.books;
  if(currentLib != null) {
    books = currentLib.books; 
  }
  return books;  
}

public void mousePressed() {
  
  if(mouseButton == RIGHT) {
     resetZoom(); 
  } else {
  
    ArrayList books = getBooks();
    for(int i = 0; i < books.size(); i++) {
      
      Book book = (Book) books.get(i);
    
      if(book.isActive()) {
        selected = book;
        labelTitle.setValue(book.title);
        labelAuthor.setValue(book.author + ", " + book.year);
        return;
      }
    }
        
    if(selected == null) {
      lasso = new Rectangle(mouseX, mouseY, 0, 0);
      return;
    }
    
    // Don't reset if click was on controls
    if(mouseY < height - 60) { 
      selected = null;
      labelTitle.setValue("(No Title Selected)");
      labelAuthor.setValue("");
    }

  }
  
  redraw();
}

public void mouseMoved() {
  redraw(); 
}

public void mouseDragged() {
  if(lasso != null) {
    lasso.setSize(mouseX - lasso.x, mouseY - lasso.y); 
  }

  redraw();
}

public void mouseReleased() {

  if(lasso != null) {
     doZoom(); 
  }
  
  lasso = null;

  redraw();  
}

// Overridden to ensure redraws when text is entered in Textfields
public void keyPressed() {
  authorQuery = textAuthor.getText();
  titleQuery = textTitle.getText();
  redraw(); 
}

public void resetZoom() {
  float vwidth = (graph.xmax - graph.xmin) * 1.05f;
  float vheight = (graph.ymax - graph.ymin) * 1.05f;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view.xStart = graph.xmin;
  view.yStart = graph.ymin;
  view.xEnd   = graph.xmin + vwidth;
  view.yEnd   = graph.ymin + vheight; 
}

public void doZoom() {
  // Only zoom if a reasonable sized area was selected
  if(lasso.width < 10 || lasso.height < 10) { return; }
  
  float mx0 = view.viewToModelX(lasso.x);
  float my0 = view.viewToModelY(lasso.y);
  float mx1 = view.viewToModelX(lasso.x + lasso.width);  
  float my1 = view.viewToModelY(lasso.y + lasso.height);

  view.xStart = min(mx0,mx1);
  view.yStart = min(my0,my1);
  view.xEnd = max(mx0,mx1);
  view.yEnd = max(my0,my1);
  
  println("Zoomed!");
}

public void controlEvent(ControlEvent theEvent) {
  int id = theEvent.controller().id();  
  if(id == libraries.size()) {
    currentLib = null;
    view.setTitle("Viewing books from All Libraries");
  } else if(id >= 0) {
    currentLib = (Library) libraries.get(id);
    view.setTitle("Viewing books from " + currentLib.name);
  }
}

public void draw() {
  background(255);

  ArrayList books = getBooks();
  view.draw(books, g);

  int yoffset = 0;

  active.clear();
  
  for(int i = 0; i < books.size(); i++) {
    Book book = (Book) books.get(i);
    
    if(book.isActive()) {
      active.add(book);
    }
  }
  
  if(selected != null) { 
    drawNeighbours(selected, false); 
    drawTitle(selected, 0);
  }
  
  drawTitles(active);
  drawLasso();
    
  controlP5.draw();
}

public void drawLasso() {
  stroke(0);
  strokeWeight(1);
  noFill();
  if(lasso != null) {
    rect(lasso.x, lasso.y, lasso.width, lasso.height);
  } 
}  
  
public void drawTitle(Book book, int offset) {
  if(book == null || ! book.isShowing()) return;
  
  stroke(0);
  fill(0);
  textFont(view.tickFont);
  float viewx = view.modelToViewX(book.x);
  float viewy = view.modelToViewY(book.y);
  text(book.title + "(" + book.readers + ")", viewx, viewy + offset);
}
  
public void drawTitles(ArrayList books) {
  int yoffset = 0;
  for(int i = 0 ; i < books.size() ;i++) {
    drawTitle((Book) books.get(i), yoffset);
    yoffset += 12;
  }
}
  
public void drawNeighbours(Book book, boolean doTitle) {
  ArrayList neighbours = (ArrayList) graph.edges.get(book);
    
  view.preDraw();    
  for(int j = 0 ; j < neighbours.size() ; j++) {
    Edge edge = (Edge) neighbours.get(j);
    Book to = edge.to;
      
    float weight = (2.0f * edge.shared) / ( book.readers + to.readers );
    if(weight > weightThreshold) {
      // Only draw edges with weight larger than the threshold
        
      if(to.isShowing()) {
        // Only draw edges to visible books 
        stroke(127 - 127*weight);
        line(book.x, book.y, to.x, to.y);
          
        if(doTitle) { drawTitle(to, 0); }
      }
    }
  }
  view.postDraw();
}
/**
 * A book is represented by its ID, title, coordinates, and number of readers.
 */
class Book extends Drawable {
	int id;
	float x, y;
	String title;
        String year;
        String author;
	int readers;
        ArrayList libraries = new ArrayList();
	
        public void draw() {
           if(readers < readerThreshold) return;
           
           fill(255-readers,255-readers*2,255-readers*2);
           stroke(127);
           ellipseMode(CENTER);
           ellipse(x, y, size(), size());            
        }

        public float size() {
           return sqrt(readers) / 7.0f; 
        }

        // Tests whether this book should be displayed.
        // FIXME: Horrible use of globals here
        public boolean isShowing() {
          return (readers >= readerThreshold) && 
                 (currentLib == null || (libraries.contains(currentLib))) &&
                 (authorQuery == null || authorQuery.length() == 0 || match(author, authorQuery) != null) &&
                 (titleQuery == null || titleQuery.length() == 0 || match(title, titleQuery) != null);
        }

        public boolean isActive() {
          if(! isShowing()) return false;

          float mx = view.viewToModelX(mouseX);
          float my = view.viewToModelY(mouseY);
          float d = (x-mx)*(x-mx) + (y-my)*(y-my);
          float r = size()/2.0f;
          return (d < r*r);
        }

	public String toString() {
	   return "Book #" + id + ": " + readers + 
                  " * \""+ title + "\" @ ("+ x + "," + y + ")";
	}
}



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

  public Book get(int workId) {
    return (Book) idToBooks.get(new Integer(workId)); 
  }

  public void addEdge(Book from, Book to, int shared) {
    ArrayList edgeList;
    if(edges.containsKey(from)) {
      edgeList = (ArrayList) edges.get(from);
    } else {
      edgeList = new ArrayList();
      edges.put(from, edgeList);
    }
    edgeList.add(new Edge(to, shared));
  }
  
  public void loadBooks(String filename) {
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
  
  public void loadEdges(String filename) {
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


// Loads library information from a CSV file of the form
//     LibraryID, Library Name, Number of Works in Library
public ArrayList loadLibraries(String filename) {
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

public void loadLibraryWorks(ArrayList libraries, String filename) {
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


class PlotView {

  PFont titleFont = createFont("Arial", 12);
  PFont tickFont  = createFont("Arial", 10);

  int grey = color(160,160,160);
  int black = color(0,0,0);
  
  String title = "[Plot Title]";
  String xAxisTitle = "[X Axis]"; String yAxisTitle = "[Y Axis]";
  int vxStart, vyStart;
  int vxEnd, vyEnd;
  float xStart, xEnd;
  float yStart, yEnd;

//  Vector drawables = new Vector();
    
  PlotView(
    int vx0, int vy0, int vWidth, int vHeight,
    float x0, float y0, float x1, float y1
  ) {
    vxStart = vx0; vyStart = vy0; vxEnd = vx0 + vWidth; vyEnd = vy0 + vHeight;
    xStart = x0; yStart = y0; xEnd = x1; yEnd = y1;
  }

  PlotView(float x0, float y0, float x1, float y1) { this(0, 0, 100, 100, x0, y0, x1, y1); }
  PlotView() { this(0.0f, 0.0f, 1.0f, 1.0f); }
  
  public void setTitle(String title) { this.title = title; }
  public void setViewStart(int vx, int vy) { vxStart = vx; vyStart = vy; }
  public void setViewEnd(int vx, int vy) { vxEnd = vx; vyEnd = vy; }
  public void setView(int vx0, int vy0, int vWidth, int vHeight) { 
    setViewStart(vx0, vy0); 
    setViewEnd(vx0 + vWidth, vHeight); 
  }
  
  public int viewWidth() { return vxEnd - vxStart; }
  public int viewHeight() { return vyEnd - vyStart; }
  
  public float xRange() { return xEnd - xStart; }
  public float yRange() { return yEnd - yStart; }
  
  public float xResolution() { return xRange() / viewWidth(); }
  public float yResolution() { return yRange() / viewHeight(); }
  
  public float viewToModelX(float vx) { return xStart + xRange() * (vx - vxStart) / viewWidth(); }
  public float viewToModelY(float vy) { return yStart - yRange() * (vy - vyEnd) / viewHeight(); }

  public float modelToViewX(float x) { return vxStart + viewWidth() * (x - xStart) / xRange(); }
  public float modelToViewY(float y) { return vyEnd - viewHeight() * (y - yStart) / yRange(); }
  
   public boolean active() {
     return (mouseX > vxStart && mouseX < vxEnd && mouseY > vyStart && mouseY < vyEnd);
   }

//   void add(Drawable drawable) { drawables.add(drawable); }

   public void preDraw() {
     pushMatrix();
     
     // Set up viewing transformations
     translate(vxStart, vyStart);
     scale(viewWidth()/xRange(),-viewHeight()/yRange());
     translate(-xStart, -yEnd);
     strokeWeight(min(xResolution(), yResolution()));     
   }
   
   public void postDraw() {
     popMatrix(); 
   }
  
   public void drawTitle() {
     fill(0);
     textFont(titleFont);
     
     textAlign(CENTER, BOTTOM);
     text(title, vxStart + viewWidth()/2, vyStart - 1);
   }
  
   public void drawBounds() {
     noFill();
     stroke(grey);
     rect(vxStart,vyStart,viewWidth(),viewHeight());

     fill(0);
     textFont(tickFont);

     // x axis
     textAlign(LEFT, TOP);
     text(nf(xStart, 1, 1), vxStart, vyEnd + 1);

     textAlign(RIGHT, TOP);
     text(nf(xEnd, 1, 1), vxEnd, vyEnd + 1);

     textAlign(CENTER, TOP);
     text(xAxisTitle, vxStart + viewWidth()/2, vyEnd + 3);

     // y axis     
     textAlign(RIGHT, BOTTOM);
     text(nf(yStart, 1, 1), vxStart - 1, vyEnd);     

     textAlign(RIGHT, TOP);
     text(nf(yEnd, 1, 1), vxStart - 1, vyStart);     
     
     textAlign(CENTER, BOTTOM);
     pushMatrix();
     translate(vxStart - 3, vyStart + viewHeight()/2);
     rotate(-PI/2.0f);
     text(yAxisTitle, 0, 0);
     popMatrix();
     
   }
  
   public void draw(ArrayList drawables, PGraphics g) {
     drawTitle();
     
     preDraw();
     for(int i = 0; i < drawables.size(); i++) {
       Drawable d = (Drawable) drawables.get(i);
       if(d != null && d.isShowing()) { d.draw(); }
     }
     postDraw();
   }
 }

class Drawable {
  // Empty implementation to be overridden
  public void draw() { }
  public boolean isShowing() { return true; }
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#ffffff", "vis" });
  }
}
