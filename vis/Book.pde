/**
 * A book is represented by its ID, title, coordinates, and number of readers.
 */
class Book extends Drawable {
	int id;
	float x, y;
	String title;
	int readers;
	
        void draw() {
           if(readers < readerThreshold) return;
           
           fill(255-readers,255-readers*2,255-readers*2);
           stroke(127);
           ellipseMode(CENTER);
           ellipse(x, y, size(), size());            
        }

        float size() {
           return sqrt(readers) / 8.5; // 70.0; 
        }

        boolean isActive() {
           if(readers < readerThreshold) return false;

          float mx = view.viewToModelX(mouseX);
          float my = view.viewToModelY(mouseY);
          float d = (x-mx)*(x-mx) + (y-my)*(y-my);
          float r = size()/2.0;
          return (d < r*r);
        }

	String toString() {
	   return "Book #" + id + ": " + readers + 
                  " * \""+ title + "\" @ ("+ x + "," + y + ")";
	}
}
