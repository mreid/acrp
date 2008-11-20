import controlP5.*;
import au.com.bytecode.opencsv.*;
import au.com.bytecode.opencsv.bean.*;
import java.io.*;

public int readerThreshold = 0;
public float weightThreshold = 0.25;
ArrayList active = new ArrayList();

Graph graph;
PlotView view;
Book selected;

ControlP5 controlP5;

void setup() {
  size(600,550, JAVA2D);
  
  frameRate(10);
  background(255);

  // Create the graph
  graph = new Graph();
  graph.loadBooks("lambton.csv");
  graph.loadEdges("lambton-neighbours.csv");
	
  float vwidth = (graph.xmax - graph.xmin) * 1.05;
  float vheight = (graph.ymax - graph.ymin) *1.05;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view = new PlotView(
    20,20,width-40,height-70,
    graph.xmin, graph.ymin, graph.xmin + vwidth, graph.ymin + vheight
  );
  view.setTitle("Books from the Lambton Miners' and Mechanics' Institute");
        
  for(int i=0; i < graph.books.size(); i++) {
    view.add((Drawable) graph.books.get(i)); 
  }

  // Controls for thresholds
  controlP5 = new ControlP5(this);
  controlP5.addSlider("weightThreshold", 0.0, 1.0, 0.25, width-220, height-30, 200, 20);
  controlP5.addTextlabel("sim", "Similarity", width-120, height-30);
  controlP5.addSlider("readerThreshold", 0, 100, 0, 20, height-30, 200, 20);  
  controlP5.addTextlabel("read", "Borrowers", 100, height-30);

  smooth();
  
  // Only draw when there is a mouse event
  noLoop();
}

void mousePressed() {
  
  for(int i = 0; i < graph.books.size(); i++) {
    Book book = (Book) graph.books.get(i);
    
    if(book.isActive()) {
      selected = book;
      return;
    }
  }
  
  // Don't reset if click was on controls
  if(mouseY < height - 50) { selected = null; }
  
  redraw();
}

void mouseMoved() {
  redraw(); 
}

void mouseDragged() {
  redraw();
}

void mouseReleased() {
  redraw();
}

void draw() {
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
  
  if(selected != null) { 
    drawNeighbours(selected, false); 
    drawTitle(selected, 0);
  }
  
  drawTitles(active);
  
  controlP5.draw();
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
