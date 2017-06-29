String DATA_DIR = "../../data/processed";
String GASES_DIR = dataDir("gas");
String IMG_DIR = dataDir("images");
String FACTORIES_FILE = _dataFile("factories");
String MONITORS_FILE = _dataFile("monitors");
String WINDS_FILE = _dataFile("winds");

int areaDim = 200;
float gasScaleFactor = 200;
float windScaleFactor = 20;
String chemical = "agoc-3a";

float offsetX = -50;
float offsetY = +20;

float scaleFactorX = 5;
float scaleFactorY = 5;

float weathervaneX;
float weathervaneY;

float[][] winds;
int n = 0;

void setup() {
  size(600, 500);
  frameRate(4);
  surface.setResizable(true);

  winds = loadFromCSV(WINDS_FILE, 1, 2);
}

void draw() {
  boolean fullLoop = false;
  try {
    background(#FFFFFF);
    fixCoords();

    recalculateScale();

    drawPoints(FACTORIES_FILE, 1, 2, #000000, 5);
    drawPoints(MONITORS_FILE, 1, 2, #0000FF, 5);
    drawPoints(gasesFile(chemical, n), 0, 2, #008000, 2);

    drawText("N", weathervaneX + 2, weathervaneY + 20);
    drawArrow(weathervaneX, weathervaneY, 20, 0, #000000, 2);

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

void drawPoints(String path, int fromCol, int toCol, int rgb, int _width) {
  float[][] points = loadFromCSV(path, fromCol, toCol);
  int dimension = toCol - fromCol + 1;

  strokeWeight(_width);

  for (float[] row : points) {
    float x = row[0];
    float y = row[1];
    
    if (dimension == 2) {
      stroke(rgb);
    } else {
      stroke(rgb, row[2] * gasScaleFactor);
    }
    point((offsetX + x) * scaleFactorX, (offsetY + y) * scaleFactorY);
  }
}

void drawWeathervane(int n, float x, float y, int rgb, int _width) {
  float[] wind = winds[n];
  float phi = radians(wind[0]);
  float speed = wind[1];
  drawArrow(x, y, speed * windScaleFactor, phi, rgb, _width);
}

void drawArrow(float x1, float y1, float r, float phi, int rgb, int _width) {
  stroke(rgb);
  fill(rgb);
  strokeWeight(_width);

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

void drawText(String txt, float x, float y) {
  pushMatrix();
  translate(x, y);
  scale(1, -1);
  text(txt, 0, 0);
  popMatrix();
}

float[][] loadFromCSV(String path, int fromCol, int toCol) {
  String[] lines = loadStrings(path);
  float[][] values = new float[lines.length][toCol - fromCol + 1];

  for (int i = 1; i < lines.length; i++) {
    String[] lineValues = split(lines[i], ',');

    for (int j = fromCol; j < toCol + 1; j++) {
      values[i][j - fromCol] = float(lineValues[j]);
    }
  }
  return values;
}

String gasesFile(String chemical, int n) {
  return GASES_DIR + "/" + chemical + "/" + n + ".csv";
}

String outputImage(String chemical, int n) {
  return IMG_DIR + "/" + chemical + "/" + n + ".png";
}

String dataDir(String path) {
  return DATA_DIR + "/" + path;
}

String _dataFile(String path) {
  return DATA_DIR + "/" + path + ".csv";
}

void recalculateScale() {
  //scaleFactorX = width / areaDim;
  //scaleFactorY = height / areaDim;
  weathervaneX = width * 0.9;
  weathervaneY = height * 0.9;
}

void fixCoords() {
  scale(1, -1);
  translate(0, -height);
}