import processing.serial.*;

PFont font;  
PGraphics pg;
PGraphics trigger, ch1Ref, ch2Ref;
PGraphics arrowUp, arrowDown;

Serial myPort;
int lf = 10;

int x = 0;
int i = 0;
int offset = 10;
int lineWidth = 3;
int boxWidth = 200;
int triggerPos = offset;
int ch1RefPos = 100;
int ch2RefPos = 200;

int gridWidth;
int gridHeight;
int[] trace1;
int[] trace2;


String inString;

int bufferSize = 1024;
byte[] packet = new byte[bufferSize];


void setup(){
  fullScreen();
  pg = createGraphics(100, 100);
  trigger= createGraphics(20, 20);
  ch1Ref = createGraphics(20, 20);
  ch2Ref = createGraphics(20, 20);
  arrowUp = createGraphics(20, 20);
  arrowDown = createGraphics(20, 20);
  
  // load font
  font = loadFont("OCRAStd-48.vlw");
  textFont(font, 32);
  
  //printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.bufferUntil(lf); 
  
  gridWidth = width-boxWidth-offset*3-lineWidth*3;
  gridHeight  = height-offset*3-lineWidth*4-60;
  trace1 = new int[bufferSize];
  trace2 = new int[bufferSize];
  
  
  for(int j = 0; j < trace1.length; j++){
    trace1[j] = j % 100;
  }
}

void draw(){
  background(0);
  drawGrid();
  drawTrace();
  drawTrigger();
  drawCh1Ref();
  drawCh2Ref();
}

void serialEvent(Serial p) {
  try{
    packet = p.readBytes();
    int channel = int(packet[0]) & 0x01;
    int packetLength = int(packet[1]) | int(packet[2])<<8;
    println("Timestamp: " + millis() + ", Channel: " + channel); 
    println("Recieved packet length: " + packetLength);
    println();
    
    for(int i = 0; i < packetLength; i++){
      trace1[i] = int(packet[i + 3]);
    }
  }
  catch(Exception e){
    println("Error occured: " + e);
  }
} 

void mousePressed(){
  //trigger.beginDraw();
  //trigger.clear();
  //trigger.endDraw();
  //triggerPos += 30;
  //drawTrigger();
  
  //ch1Ref.beginDraw();
  //ch1Ref.clear();
  //ch1Ref.endDraw();
  //ch1RefPos += 10;
  //drawCh1Ref();
  
  //ch2Ref.beginDraw();
  //ch2Ref.clear();
  //ch2Ref.endDraw();
  //ch2RefPos += 10;
  //drawCh2Ref();
  
  //println("X=" + mouseX);
  //println("Y=" + mouseY);
}

void drawTrigger(){
  trigger.beginDraw();
  trigger.fill(#27fffa);
  trigger.noStroke();
  trigger.triangle(0, 10, 10, 0, 20, 10);
  trigger.endDraw();
  image(trigger, triggerPos+10, offset+60+10);
}

void drawCh1Ref(){
  ch1Ref.beginDraw();
  ch1Ref.noStroke();
  ch1Ref.fill(#27fffa);
  ch1Ref.triangle(0, 10, 10, 0, 10, 20);
  ch1Ref.rect(10, 0, 20, 20);
  ch1Ref.fill(0);
  ch1Ref.textFont(font, 14);
  ch1Ref.text("1", 8,15);
  ch1Ref.endDraw();
  image(ch1Ref, offset+10, ch1RefPos);
}

void drawCh2Ref(){
  ch2Ref.beginDraw();
  ch2Ref.noStroke();
  ch2Ref.fill(#ff0088);
  ch2Ref.triangle(0, 10, 10, 0, 10, 20);
  ch2Ref.rect(10, 0, 20, 20);
  ch2Ref.fill(0);
  ch2Ref.textFont(font, 14);
  ch2Ref.text("2", 8,15);
  ch2Ref.endDraw();
  image(ch2Ref, offset+10, ch2RefPos);
}

void drawGrid(){
  stroke(#36fdf6);
  strokeWeight(lineWidth);
  noFill();
  rect(offset, offset, width-offset*2-lineWidth, height-offset*2-lineWidth);
  line(offset, offset+60, width-offset-lineWidth, offset+60);
  rect(width-offset-boxWidth, offset+60, boxWidth-lineWidth, height-offset*2-60-lineWidth);
  line(width-offset-lineWidth, offset+370, width-offset-boxWidth, offset+370);
  
  // grid
  stroke(255);
  strokeWeight(1);
  line(offset + 10, 70, width-offset-10, 70);
  
  // title
  fill(255);
  textFont(font, 32);
  text("uSCOPE", 32, 50);
  
  textFont(font, 14);
  text("22/03/2017 01:00 PM", width-250, 50);
  
  // config title
  fill(255);
  textFont(font, 16);
  text("HORIZONTAL", width-boxWidth, offset+100);
  text("VERTICAL", width-boxWidth, offset+200);
  text("TRIGGER", width-boxWidth, offset+300);
  text("CH1 MEASUREMENT", width-boxWidth, offset+400);
  text("CH2 MEASUREMENT", width-boxWidth, offset+500);
  
  // info
  noFill();
  stroke(#55bf5b);
  rect(width-boxWidth+offset, offset+110, 140, 20);
  arrowUp.beginDraw();
  arrowUp.fill(#55bf5b);
  arrowUp.noStroke();
  arrowUp.triangle(0, 10, 10, 0, 20, 10);
  arrowUp.endDraw();
  image(arrowUp, width-boxWidth+offset+60, offset+115);
  arrowDown.beginDraw();
  arrowDown.fill(#55bf5b);
  arrowDown.noStroke();
  arrowDown.triangle(0, 0, 10, 10, 20, 0);
  arrowDown.endDraw();
  image(arrowDown, width-boxWidth+offset+60, offset+165);
  
  rect(width-boxWidth+offset, offset+160, 140, 20);
  fill(#55bf5b);
  text("10.00 uS/DIV", width-boxWidth+offset, offset+150);
  
  text("10.00 mV/DIV", width-boxWidth+offset, offset+220);
  text("CH1", width-boxWidth+offset, offset+320);
  text("20.00 mV POS.", width-boxWidth+offset, offset+340);
  text("100.00 mVpp", width-boxWidth+offset, offset+420);
  text("1.000MHz", width-boxWidth+offset, offset+440);
  text("100.00 mVpp", width-boxWidth+offset, offset+520);
  text("1.000MHz", width-boxWidth+offset, offset+540);
  
  // grid
  stroke(255);
  noFill();
  rect(offset*2, offset*2+60, gridWidth, gridHeight );
  for(int i=1; i<10; i++){
    // inbox
    stroke(#4a4a4a);
    line((i*gridWidth/10)+offset*2, offset*2+60, (i*gridWidth/10)+offset*2, offset*2+60+gridHeight);
    line(offset*2, (i*gridHeight/10)+offset*2+60, offset*2+gridWidth, (i*gridHeight/10)+offset*2+60);
    // outbox
    stroke(255);
    line((i*gridWidth/10)+offset*2, offset*2+60, (i*gridWidth/10)+offset*2, offset*2+60+10);
    line((i*gridWidth/10)+offset*2, offset*2+60+gridHeight, (i*gridWidth/10)+offset*2, offset*2+60-10+gridHeight);
    line(gridWidth+offset*2, (i*gridHeight/10)+offset*2+60, gridWidth+offset*2-10, (i*gridHeight/10)+offset*2+60);
    line(offset*2, (i*gridHeight/10)+offset*2+60, offset*2+10, (i*gridHeight/10)+offset*2+60);
  }
  
  // inner-scale
  stroke(#4a4a4a);
  for(int i=1; i<50; i++){
    line((i*gridWidth/50)+offset*2, gridHeight/2+offset*2+60-5, (i*gridWidth/50)+offset*2, gridHeight/2+offset*2+60+5); // x
    line(gridWidth/2+offset*2+5, (i*gridHeight/50)+offset*2+60, gridWidth/2+offset*2-5, (i*gridHeight/50)+offset*2+60); // y
  }
  
  
  // sample line
  //stroke(#27fffa);
  strokeWeight(lineWidth);
  //float a = 0.0;
  //float inc = TWO_PI / gridWidth;
  //for(int i=0; i<gridWidth; i++){
  //   line(offset*2+i, gridHeight/2+offset*2+60+50*cos(a-inc), offset*2+i+1, gridHeight/2+offset*2+60+50*cos(a));
  //   a = a + inc;
  //}
  //stroke(#ff0088);
  //for(int i=0; i<gridWidth; i++){
  //   line(offset*2+i, gridHeight/2+offset*2+60+100*sin(a-inc), offset*2+i+1, gridHeight/2+offset*2+60+100*sin(a));
  //   a = a + inc;m
  //}
  
  // fps
  fill(255);
  text(frameRate + " fps", width-200, height-100);
}

void drawTrace(){
  float inc = (float) gridWidth/bufferSize;
  stroke(#27fffa);
  for(int i = 1; i < bufferSize; i++){
    line(
      offset*2+(i*inc), 
      gridHeight/2+offset*2+60-trace1[i-1], 
      offset*2+(i*inc)+inc, 
      gridHeight/2+offset*2+60-trace1[i]
    );
  }
  //stroke(#ff0088);
  //for(int i = 1; i < trace1.length; i++){
  //  line(offset*2+i, gridHeight/4+offset+trace2[i-1], offset*2+i+1, gridHeight/4+offset+trace2[i]);
  //}
}