import controlP5.*;
import au.com.bytecode.opencsv.*;
import au.com.bytecode.opencsv.bean.*;
import java.io.*;
import java.awt.Rectangle;

public int readerThreshold = 0;
public float weightThreshold = 0.25;
ArrayList active = new ArrayList();

Graph graph;
PlotView view;
Book selected;
Rectangle lasso;

ControlP5 controlP5;
Textlabel labelTitle;

void setup() {
//  size(600,550, JAVA2D);
  size(800,750, JAVA2D);
  
  frameRate(10);
  background(255);

  // Create the graph
  graph = new Graph();
  graph.loadBooks("lambton.csv");
  graph.loadEdges("lambton-neighbours.csv");
	
  float vwidth = (graph.xmax - graph.xmin) * 1.05;
  float vheight = (graph.ymax - graph.ymin) * 1.05;

  // Create the view with 20 pixel horizontal margin and 50 pixel bottom margin
  view = new PlotView(
    20,20,width-40,height-100,
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

  labelTitle = controlP5.addTextlabel("title", "(No Title Selected)                                   ", 20, height-50);
  labelTitle.setColorValue(0);  

  smooth();
  
  // Only draw when there is a mouse event
  noLoop();
}


void mousePressed() {
  
  if(mouseButton == RIGHT) {
     resetZoom(); 
  } else {
  
    for(int i = 0; i < graph.books.size(); i++) {
      Book book = (Book) graph.books.get(i);
    
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
  float mx0 = view.viewToModelX(lasso.x);
  float my0 = view.viewToModelY(lasso.y);
  float mx1 = view.viewToModelX(lasso.x + lasso.width);  
  float my1 = view.viewToModelY(lasso.y + lasso.height);

  view.xStart = min(mx0,mx1);
  view.yStart = min(my0,my1);
  view.xEnd = max(mx0,mx1);
  view.yEnd = max(my0,my1);
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
