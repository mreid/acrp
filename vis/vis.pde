import controlP5.*;
import au.com.bytecode.opencsv.*;
import au.com.bytecode.opencsv.bean.*;
import java.io.*;
import java.awt.Rectangle;

String basedir = "lambton-5";

public int readerThreshold = 0;
public float weightThreshold = 0.25;
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

void setup() {
//  size(600,550, JAVA2D);
  size(800,750, JAVA2D);
  
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

  float vwidth = (graph.xmax - graph.xmin) * 1.05;
  float vheight = (graph.ymax - graph.ymin) * 1.05;

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
  controlP5.addSlider("weightThreshold", 0.0, 1.0, 0.25, width-220, height-30, 200, 20);
  controlP5.addTextlabel("sim", "Similarity", width-120, height-30);
  controlP5.addSlider("readerThreshold", 0, 100, 0, 20, height-30, 200, 20);  
  controlP5.addTextlabel("read", "Borrowers", 100, height-30);

  labelTitle = controlP5.addTextlabel("title", "(No Title Selected)                                   ", 20, height-50);
  labelTitle.setColorValue(0);  

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

  smooth();  
}

ArrayList getBooks() {
  ArrayList books = graph.books;
  if(currentLib != null) {
    books = currentLib.books; 
  }
  return books;  
}

void mousePressed() {
  
  if(mouseButton == RIGHT) {
     resetZoom(); 
  } else {
  
    ArrayList books = getBooks();
    for(int i = 0; i < books.size(); i++) {
      
      Book book = (Book) books.get(i);
    
      if(book.isActive()) {
        selected = book;
        labelTitle.setValue(book.title + ", " + book.author + " (" + book.year + ")");
        return;
      }
    }
        
    if(selected == null) {
      lasso = new Rectangle(mouseX, mouseY, 0, 0);
      return;
    }
    
    // Don't reset if click was on controls
    if(mouseY < height - 50) { 
      selected = null;
      labelTitle.setValue("(No Title Selected)");
    }

  }
  
  redraw();
}

void mouseMoved() {
  redraw(); 
}

void mouseDragged() {
  if(lasso != null) {
    lasso.setSize(mouseX - lasso.x, mouseY - lasso.y); 
  }

  redraw();
}

void mouseReleased() {

  if(lasso != null) {
     doZoom(); 
  }
  
  lasso = null;

  redraw();  
}

void resetZoom() {
  float vwidth = (graph.xmax - graph.xmin) * 1.05;
  float vheight = (graph.ymax - graph.ymin) * 1.05;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view.xStart = graph.xmin;
  view.yStart = graph.ymin;
  view.xEnd   = graph.xmin + vwidth;
  view.yEnd   = graph.ymin + vheight; 
}

void doZoom() {
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

void controlEvent(ControlEvent theEvent) {
  int id = theEvent.controller().id();
  println("ID = " + id);
  if(id == libraries.size()) {
    currentLib = null;
    view.setTitle("Viewing books from All Libraries");
  } else if(id >= 0) {
    currentLib = (Library) libraries.get(id);
    view.setTitle("Viewing books from " + currentLib.name);
    println("Library = " + currentLib.name + "," + currentLib.books.size());
  }
}

void draw() {
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

void drawLasso() {
  stroke(0);
  strokeWeight(1);
  noFill();
  if(lasso != null) {
    rect(lasso.x, lasso.y, lasso.width, lasso.height);
  } 
}
  
void drawTitle(Book book, int offset) {
  if(book == null) return;
  
  stroke(0);
  fill(0);
  textFont(view.tickFont);
  float viewx = view.modelToViewX(book.x);
  float viewy = view.modelToViewY(book.y);
  text(book.title + "(" + book.readers + ")", viewx, viewy + offset);
}
  
void drawTitles(ArrayList books) {
  int yoffset = 0;
  for(int i = 0 ; i < books.size() ;i++) {
    drawTitle((Book) books.get(i), yoffset);
    yoffset += 12;
  }
}
  
void drawNeighbours(Book book, boolean doTitle) {
  ArrayList neighbours = (ArrayList) graph.edges.get(book);
    
  view.preDraw();    
  for(int j = 0 ; j < neighbours.size() ; j++) {
    Edge edge = (Edge) neighbours.get(j);
    Book to = edge.to;
      
    float weight = (2.0 * edge.shared) / ( book.readers + to.readers );
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
