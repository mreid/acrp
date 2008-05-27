import java.util.Vector;

class PlotView {

  PFont titleFont = createFont("Arial", 12);
  PFont tickFont  = createFont("Arial", 10);

  color grey = color(160,160,160);
  color black = color(0,0,0);
  
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
  PlotView() { this(0.0, 0.0, 1.0, 1.0); }
  
  void setTitle(String title) { this.title = title; }
  void setViewStart(int vx, int vy) { vxStart = vx; vyStart = vy; }
  void setViewEnd(int vx, int vy) { vxEnd = vx; vyEnd = vy; }
  void setView(int vx0, int vy0, int vWidth, int vHeight) { 
    setViewStart(vx0, vy0); 
    setViewEnd(vx0 + vWidth, vHeight); 
  }
  
  int viewWidth() { return vxEnd - vxStart; }
  int viewHeight() { return vyEnd - vyStart; }
  
  float xRange() { return xEnd - xStart; }
  float yRange() { return yEnd - yStart; }
  
  float xResolution() { return xRange() / viewWidth(); }
  float yResolution() { return yRange() / viewHeight(); }
  
  float viewToModelX(float vx) { return xStart + xRange() * (vx - vxStart) / viewWidth(); }
  float viewToModelY(float vy) { return yStart - yRange() * (vy - vyEnd) / viewHeight(); }

  float modelToViewX(float x) { return vxStart + viewWidth() * (x - xStart) / xRange(); }
  float modelToViewY(float y) { return vyEnd - viewHeight() * (y - yStart) / yRange(); }
  
   boolean active() {
     return (mouseX > vxStart && mouseX < vxEnd && mouseY > vyStart && mouseY < vyEnd);
   }

	void add(Drawable drawable) { drawables.add(drawable); }

   void preDraw() {
     pushMatrix();
     
     // Set up viewing transformations
     translate(vxStart, vyStart);
     scale(viewWidth()/xRange(),-viewHeight()/yRange());
     translate(-xStart, -yEnd);
     strokeWeight(min(xResolution(), yResolution()));     
   }
   
   void postDraw() {
     popMatrix(); 
   }
  
   void drawTitle() {
     fill(0);
     textFont(titleFont);
     
     textAlign(CENTER, BOTTOM);
     text(title, vxStart + viewWidth()/2, vyStart - 1);
   }
  
   void drawBounds() {
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
     rotate(-PI/2.0);
     text(yAxisTitle, 0, 0);
     popMatrix();
     
   }
  
   void draw(PGraphics g) {
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
	void draw() {
		
	}
}
