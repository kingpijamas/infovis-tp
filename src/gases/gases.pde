String dataDir = "../../data/processed";
String gasesDir = dataDir + "/gas";
String outputDir = dataDir + "/images";
String factoriesFile = dataDir + "/factories.csv";
String monitorsFile = dataDir + "/monitors.csv";
String windsFile = dataDir + "/winds.csv";

int areaDim = 200;
float scaleFactor = 4;
float gasScaleFactor = 200;
float windScaleFactor = 20;
String chemical = "agoc-3a";
float weathervaneX = 1000 / 2;
float weathervaneY = 1000 / 2;

float[][] winds;
int n = 0;

void setup() {
  size(800, 800);
  frameRate(2);
  surface.setResizable(true);
  
  winds = loadFromCSV(windsFile, 1, 2);
}

void draw() {
  boolean fullLoop = false;
  try {
    background(#FFFFFF);
    fixCoords();

    drawPoints(factoriesFile, 1, 2, #000000, 5);
    drawPoints(monitorsFile, 1, 2, #0000FF, 5);
    drawPoints(gasesFile(chemical, n), 0, 2, #008000, 2);

    if (n > 0) {
      drawWeathervane(n - 1, weathervaneX, weathervaneY, #808080, 2);
    }
    drawWeathervane(n, weathervaneX, weathervaneY, #000000, 2);
    
    if (!fullLoop) {
      save(outputImage(chemical, n));
    }

    n += 1;
  } catch (Exception e) {
    n = 0;
    fullLoop = true;
  }
}

void drawPoints(String path, int fromCol, int toCol, int pointRGB, int pointWidth) {
  float[][] points = loadFromCSV(path, fromCol, toCol);
  int dimension = toCol - fromCol + 1;

  strokeWeight(pointWidth);

  for (float[] row : points) {
    if (dimension == 2) {
      stroke(pointRGB);
      point(row[0] * scaleFactor, row[1] * scaleFactor);
    } else {
      stroke(pointRGB, row[2] * gasScaleFactor);
      point(row[0] * scaleFactor, row[1] * scaleFactor);
    }
  }
}

void drawWeathervane(int n, float x, float y, int weathervaneRGB, int weathervaneWidth) {
  float[] wind = winds[n];
  float phi = radians(wind[0] * -1);
  float speed = wind[1];
  drawArrow(x, y, speed * windScaleFactor, phi, weathervaneRGB, weathervaneWidth);
}

void drawArrow(float x1, float y1, float r, float phi, int arrowRGB, int arrowWidth) {
  stroke(arrowRGB);
  fill(arrowRGB);
  strokeWeight(arrowWidth);

  float x2 = x1 + r * sin(phi);
  float y2 = y1 + r * cos(phi);
  float a = dist(x1, y1, x2, y2) / 20;
  pushMatrix();
  translate(x2, y2);
  rotate(atan2(y2 - y1, x2 - x1));
  triangle(- a * 2 , - a, 0, 0, - a * 2, a);
  popMatrix();
  line(x1, y1, x2, y2);
}

float[][] loadFromCSV(String path, int fromCol, int toCol) {
  String[] lines = loadStrings(path);
  float[][] values = new float[lines.length][toCol - fromCol + 1];

  for (int i = 1; i < lines.length; i++) {
    String[] lineValues = split(lines[i], ',');

    for (int j = fromCol; j < toCol + 1; j++) {
      values[i][j - fromCol] = float(lineValues[j]);
    }
    //println(values[i]);
  }
  return values;
}

String gasesFile(String chemical, int n) {
  return gasesDir + "/" + chemical + "/" + n + ".csv";
}

String outputImage(String chemical, int n) {
  return outputDir + "/" + chemical + "/" + n + ".png";
}

void fixCoords() {
  scale(1, -1);
  translate(0, -height);  
}