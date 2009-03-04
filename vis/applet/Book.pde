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
	
        void draw() {
           if(readers < readerThreshold) return;
           
           fill(255-readers,255-readers*2,255-readers*2);
           stroke(127);
           ellipseMode(CENTER);
           ellipse(x, y, size(), size());            
        }

        float size() {
           return sqrt(readers) / 7.0; 
        }

        // Tests whether this book should be displayed.
        // FIXME: Horrible use of globals here
        boolean isShowing() {
          return (readers >= readerThreshold) && 
                 (currentLib == null || (libraries.contains(currentLib))) &&
                 (authorQuery == null || authorQuery.length() == 0 || match(author, authorQuery) != null) &&
                 (titleQuery == null || titleQuery.length() == 0 || match(title, titleQuery) != null);
        }

        boolean isActive() {
          if(! isShowing()) return false;

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
