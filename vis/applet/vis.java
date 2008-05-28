import processing.core.*; import controlP5.*; import au.com.bytecode.opencsv.*; import au.com.bytecode.opencsv.bean.*; import java.io.*; import java.util.Hashtable; import java.util.ArrayList; import java.util.Vector; import java.applet.*; import java.awt.*; import java.awt.image.*; import java.awt.event.*; import java.io.*; import java.net.*; import java.text.*; import java.util.*; import java.util.zip.*; import javax.sound.midi.*; import javax.sound.midi.spi.*; import javax.sound.sampled.*; import javax.sound.sampled.spi.*; import java.util.regex.*; import javax.xml.parsers.*; import javax.xml.transform.*; import javax.xml.transform.dom.*; import javax.xml.transform.sax.*; import javax.xml.transform.stream.*; import org.xml.sax.*; import org.xml.sax.ext.*; import org.xml.sax.helpers.*; public class vis extends PApplet {




int readerThreshold = 0;
float weightThreshold = 0.25f;
ArrayList active = new ArrayList();

Graph graph;
PlotView view;
Book selected;

public void setup() {
  size(600,550, JAVA2D);
  
  frameRate(10);
  background(255);


  // Create the graph
  graph = new Graph();
  graph.loadBooks("lambton.csv");
  graph.loadEdges("lambton-neighbours.csv");
	
  float vwidth = (graph.xmax - graph.xmin) * 1.05f;
  float vheight = (graph.ymax - graph.ymin) *1.05f;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view = new PlotView(
    20,20,width-40,height-70,
    graph.xmin, graph.ymin, graph.xmin + vwidth, graph.ymin + vheight
  );
  view.setTitle("Books from the Lambton Library");
        
  for(int i=0; i < graph.books.size(); i++) {
    view.add((Drawable) graph.books.get(i)); 
  }

  // Controls for thresholds
  ControlP5 controlP5 = new ControlP5(this);
  controlP5.addSlider("weightThreshold", 0.0f, 1.0f, 0.25f, width-220, height-30, 200, 20);
  controlP5.addTextlabel("sim", "Similarity", width-120, height-30);
  controlP5.addSlider("readerThreshold", 0, 100, 0, 20, height-30, 200, 20);  
  controlP5.addTextlabel("read", "Readers", 100, height-30);
  smooth();
}

public void mousePressed() {
  for(int i = 0; i < graph.books.size(); i++) {
    Book book = (Book) graph.books.get(i);
    
    if(book.isActive()) {
      selected = book;
      return;
    }
  }
  
  // Don't reset if click was on controls
  if(mouseY < height - 50) { selected = null; }
}

public void draw() {
  background(255);

  view.draw(g);

  int yoffset = 0;

  active.clear();
  for(int i = 0; i < graph.books.size(); i++) {
    Book book = (Book) graph.books.get(i);
    
    if(book.isActive()) {
      active.add(book);
    }
  }
  
  drawTitles(active);
  if(selected != null) { 
    drawTitle(selected, 0);
    drawNeighbours(selected, true); 
  }
  
}
  
public void drawTitle(Book book, int offset) {
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
        
      if(to.readers >= readerThreshold) {
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
	int readers;
	
        public void draw() {
           if(readers < readerThreshold) return;
           
           fill(255-readers,255-readers*2,255-readers*2);
           stroke(127);
           ellipseMode(CENTER);
           ellipse(x, y, size(), size());            
        }

        public float size() {
           return readers / 70.0f; 
        }

        public boolean isActive() {
           if(readers < readerThreshold) return false;

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

  float xmin = Float.POSITIVE_INFINITY;
  float ymin = Float.POSITIVE_INFINITY; 
  float xmax = Float.NEGATIVE_INFINITY; 
  float ymax = Float.NEGATIVE_INFINITY;

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
        book.readers = Integer.parseInt(row[3]);
        book.x = Float.parseFloat(row[4]);
        book.y = Float.parseFloat(row[5]);

        // Books are added in order read, which should be sorted by ID by
        // the R program that generated the file being read. 
        books.add(book);

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
  int  shared;
  
  Edge(Book to, int shared) {
    this.to = to;
    this.shared = shared; 
  }
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

  Vector drawables = new Vector();
    
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

	public void add(Drawable drawable) { drawables.add(drawable); }

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
  
   public void draw(PGraphics g) {
     drawTitle();
//     drawBounds();
     
     preDraw();
     for(int i = 0; i < drawables.size(); i++) {
       ((Drawable) drawables.get(i)).draw();
     }
     postDraw();
   }
 }

class Drawable {
	// Empty implementation to be overridden
	public void draw() {
		
	}
}

  static public void main(String args[]) {     PApplet.main(new String[] { "vis" });  }}