import au.com.bytecode.opencsv.*;
import au.com.bytecode.opencsv.bean.*;
import java.io.*;

int readerThreshold = 0;

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
           return readers / 70.0; 
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

ArrayList books = new ArrayList();
PlotView view;

void setup() {
	size(500,500, JAVA2D);
        frameRate(10);
        background(255);

	CSVReader reader = new CSVReader(
		new InputStreamReader(openStream("lambton.csv"))
	);

	float xmin =Float.POSITIVE_INFINITY;
	float ymin = Float.POSITIVE_INFINITY; 
	float xmax = Float.NEGATIVE_INFINITY; 
	float ymax = Float.NEGATIVE_INFINITY;

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
			books.add(book);

			xmin = min(xmin, book.x); ymin = min(ymin, book.y);
			xmax = max(xmax, book.x); ymax = max(ymax, book.y);
		}
	} catch (IOException ioe) {
  
	}

	println("Books added: " + books.size());

	smooth();
	
        float vwidth = (xmax - xmin) * 1.05;
        float vheight = (ymax - ymin) *1.05;

        view = new PlotView(20,20,460,460,xmin,ymin,xmin + vwidth,ymin + vheight);
        view.setTitle("Books from the Lambton Library");
        
        for(int i=0; i < books.size(); i++) {
          view.add((Drawable) books.get(i)); 
        }
}

void draw() {
  background(255);
  view.draw(g);
  int yoffset = 0;
  for(int i = 0; i < books.size(); i++) {
    Book book = (Book) books.get(i);
    if(book.isActive()) {
      stroke(0);
      fill(0);
      textFont(view.tickFont);
      text(book.title + "(" + book.readers + ")", mouseX, mouseY + yoffset);
      yoffset += 12;
    } 
  }
}
