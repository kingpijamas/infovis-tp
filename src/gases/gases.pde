int areaDim = 200;
float scaleFactor = 5;
float gasScaleFactor = 200;

String factoriesFile = "../../data/processed/factories.csv";
String monitorsFile = "../../data/processed/monitors.csv";
String gasesFile = "../../data/processed/gas/agoc-3a/3.csv";

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

void printPoints(String path, int fromCol, int toCol, int pointRGB, int pointWidth, float gasScaleFactor) {
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

void setup() {
  size(1000, 1000);

  printPoints(factoriesFile, 1, 2, #000000, 5, 1);
  printPoints(monitorsFile, 1, 2, #0000FF, 5, 1);
  printPoints(gasesFile, 0, 2, #008000, 2, gasScaleFactor);
}