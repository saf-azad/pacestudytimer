/* ADHD Study Timer App – touch-friendly Processing sketch
 * --------------------------------------------------------
 * Layout fix: numeric time now sits BETWEEN the rows of up/down triangles.
 * Design:             ▲   ▲   ▲
 * HH:MM:SS
 * ▼   ▼   ▼
 * Arrows stay equidistant; START button moved further down to keep spacing.
 * * Fixes:
 * - Adjusted positioning for the three main buttons (BACK, RESET, BREAK) on the TIMER screen
 * to be properly centered.
 * - Introduced a separate hitbox for the BACK button on the BREAK screen (`breakBackHit`)
 * to allow for correct alignment with the END BREAK button.
 * - Aligned the BACK and END BREAK buttons on the BREAK screen as a centered pair.
 * - Re-added hour and second adjustment triangles for study time.
 * - The "Total Minutes" text input for study time now synchronizes with arrow adjustments,
 * and applying typed input updates the main HH:MM:SS display.
 * - Added a customizable break time section with its own hour, minute, second arrows,
 * and a "Total Minutes" input field.
 * - Compacted the setup screen layout to fit both study and break customization.
 * - UPDATED: Made the break time input smaller by removing hour adjustment arrows and
 * the "Total Minutes" input field for break duration. Break time is now adjusted
 * only by minutes and seconds using up/down arrows.
 * - FIX: Removed 'final' keyword from 'breakSeconds' to allow it to be assigned and customized.
 */

// ---------- MODES ----------
final int SETUP = 0;
final int TIMER = 1;
final int BREAK = 2;
final int CONFIRM_RESET = 3;
final int CONFIRM_BACK = 4;
int mode = SETUP;

// ---------- SESSION SETTINGS ----------
int     sessionSeconds = 25 * 60;        // default 25-min study
int     timeLeft         = sessionSeconds;
int     breakSeconds = 5 * 60;        // 5-min breaks - REMOVED 'final' keyword
int     breakLeft      = breakSeconds;

boolean running  = false;
int     lastTick = 0;

// ---------- SMOOTH ANIMATION ----------
float displayTime = sessionSeconds;     // smooth interpolated time for display
float displayBreakTime = breakSeconds;  // smooth interpolated break time
final float GLIDE_SPEED = 0.05;         // animation speed (0.01 = slow, 0.1 = fast)

// ---------- UI FONTS ----------
PFont fontLarge, fontSmall;

// ---------- HALO GEOMETRY ----------
float centreX, centreY, ringDia;

// ---------- HITBOXES ----------
// Study time adjustment arrows
Rectangle hrUp, hrDown, mnUp, mnDown, scUp, scDown;
// Break time adjustment arrows (Removed hour arrows)
Rectangle brMnUp, brMnDown, brScUp, brScDown;

Rectangle startHit, breakHit, resetHit, backHit; // backHit is for TIMER screen
Rectangle breakBackHit, endBreakHit; // New: breakBackHit for BREAK screen
Rectangle confirmYes, confirmNo;  // For reset confirmation popup

// Variables for study time text input
String typedMinutesString = ""; // Stores the text typed by the user for study time
boolean isMinutesInputActive = false; // True when the study input field is selected
Rectangle minutesInputBox; // Hitbox for the study input field

// Variables for break time text input (Removed typedBreakMinutesString and isBreakMinutesInputActive)
// Rectangle breakMinutesInputBox; // Removed as per user request


void setup() {
  size(400, 600);
  smooth();

  centreX = width / 2.0;
  centreY = height / 2.0 - 40; // This centreY is primarily for the halo, not setup screen layout.
  ringDia = 300;

  fontLarge = createFont("Arial", 48);
  fontSmall = createFont("Arial", 18);

  computeHitboxes();
}

void draw() {
  switch (mode) {
    case SETUP: drawSetup(); break;
    case TIMER: drawTimer(); break;
    case BREAK: drawBreak(); break;
    case CONFIRM_RESET: drawConfirmReset(); break;
    case CONFIRM_BACK: drawConfirmBack(); break;
  }
  updateTimers();
}

// =================   SETUP SCREEN   =================
void drawSetup() {
  background(0);
  textAlign(CENTER, CENTER);
  textFont(fontSmall);
  fill(255);

  // --- Study Duration Section ---
  text("Set study duration", centreX, STUDY_TITLE_Y);

  // Study time cyan triangles
  drawTriangle(hrUp,    color(0,220,255));
  drawTriangle(hrDown, color(0,220,255), true);
  drawTriangle(mnUp,    color(0,220,255));
  drawTriangle(mnDown, color(0,220,255), true);
  drawTriangle(scUp,    color(0,220,255));
  drawTriangle(scDown, color(0,220,255), true);

  // Display current session time (HH:MM:SS)
  int hrs  = sessionSeconds / 3600;
  int mins = (sessionSeconds % 3600) / 60;
  int secs = sessionSeconds % 60;
  textFont(fontLarge);
  fill(255,50,240);
  text(nf(hrs,2)+":"+nf(mins,2)+":"+nf(secs,2), centreX, STUDY_TEXT_Y);

  // Draw the study minutes input box
  noStroke();
  fill(isMinutesInputActive ? color(60) : color(30)); // Highlight when active
  rect(minutesInputBox.x, minutesInputBox.y, minutesInputBox.w, minutesInputBox.h, 8);

  textFont(fontSmall);
  fill(180);
  text("Total Minutes:", minutesInputBox.x - 60, minutesInputBox.y + minutesInputBox.h/2);

  textFont(fontLarge); // Use large font for input numbers
  fill(255);
  if (isMinutesInputActive) {
    text(typedMinutesString + ((frameCount / 30) % 2 == 0 ? "|" : ""), // Blinking cursor
         minutesInputBox.x + minutesInputBox.w/2, minutesInputBox.y + minutesInputBox.h/2);
  } else {
    // Display the current sessionSeconds in minutes when not active
    text(str(sessionSeconds / 60), minutesInputBox.x + minutesInputBox.w/2, minutesInputBox.y + minutesInputBox.h/2);
  }

  // --- Break Duration Section ---
  textFont(fontSmall);
  fill(255);
  text("Set break duration", centreX, BREAK_TITLE_Y);

  // Break time cyan triangles (only minutes and seconds now)
  drawTriangle(brMnUp,    color(0,220,255));
  drawTriangle(brMnDown, color(0,220,255), true);
  drawTriangle(brScUp,    color(0,220,255));
  drawTriangle(brScDown, color(0,220,255), true);

  // Display current break time (HH:MM:SS)
  hrs  = breakSeconds / 3600;
  mins = (breakSeconds % 3600) / 60;
  secs = breakSeconds % 60;
  textFont(fontLarge);
  fill(255,50,240);
  text(nf(hrs,2)+":"+nf(mins,2)+":"+nf(secs,2), centreX, BREAK_TEXT_Y);

  // Removed: Draw the break minutes input box
  // Removed: text("Total Minutes:", breakMinutesInputBox.x - 60, breakMinutesInputBox.y + breakMinutesInputBox.h/2);


  // START button
  drawButton(startHit, "START", color(50,255,100));
}

// =================   TIMER SCREEN   =================
void drawTimer() {
  background(0);
  
  // Smooth interpolation for gliding effect
  displayTime = lerp(displayTime, timeLeft, GLIDE_SPEED);
  float frac = displayTime / sessionSeconds;
  drawHalo(centreX, centreY, ringDia, frac, color(0,200,255), color(40));

  // Display the smoothly animated time
  int displayMinutes = (int)(displayTime / 60);
  int displaySeconds = (int)(displayTime % 60);
  
  textFont(fontLarge);
  fill(255);
  text(nf(displayMinutes,2)+":"+nf(displaySeconds,2), centreX, centreY);

  // Position the pause/resume text inside the circle, below the timer
  textFont(fontSmall);
  fill(120);
  text(running ? "Tap ring to pause" : "Tap ring to resume", centreX, centreY + 50);

  // Three buttons side by side
  drawButton(backHit, "BACK", color(150,150,150));
  drawButton(resetHit, "RESET", color(0,255,180));
  drawButton(breakHit, "BREAK", color(255,100,0));
}

// =================   BREAK SCREEN   =================
void drawBreak() {
  background(0);
  
  // Smooth interpolation for break timer
  displayBreakTime = lerp(displayBreakTime, breakLeft, GLIDE_SPEED);
  float frac = displayBreakTime / breakSeconds;
  drawHalo(centreX, centreY, ringDia, frac, color(255,100,0), color(40));

  // Display the smoothly animated break time
  int displayMinutes = (int)(displayBreakTime / 60);
  int displaySeconds = (int)(displayBreakTime % 60);

  textFont(fontLarge);
  fill(255);
  text(nf(displayMinutes,2)+":"+nf(displaySeconds,2), centreX, centreY);

  // Use the newly defined breakBackHit for the BACK button on the break screen
  drawButton(breakBackHit, "BACK", color(150,150,150));
  drawButton(endBreakHit, "END BREAK", color(0,255,180)); // endBreakHit is now aligned

  textFont(fontSmall);
  fill(120);
  text("5-min break", centreX, centreY + 50);
}

// =================   CONFIRMATION POPUP   =================
void drawConfirmReset() {
  // Draw the current timer screen in background (dimmed)
  drawTimer();
  
  // Semi-transparent overlay
  fill(0, 180);
  rect(0, 0, width, height);
  
  // Popup box
  float boxW = 280, boxH = 160;
  float boxX = (width - boxW) / 2;
  float boxY = (height - boxH) / 2;
  
  fill(40);
  stroke(100);
  strokeWeight(2);
  rect(boxX, boxY, boxW, boxH, 12);
  
  // Popup text
  textAlign(CENTER, CENTER);
  textFont(fontSmall);
  fill(255);
  text("Are you sure you want to", boxX + boxW/2, boxY + 40);
  text("reset your timer?", boxX + boxW/2, boxY + 60);
  
  // Yes/No buttons
  drawButton(confirmYes, "YES", color(255,80,80));
  drawButton(confirmNo, "NO", color(80,255,80));
  
  textAlign(CENTER, CENTER); // Reset alignment
}

// =================   BACK CONFIRMATION POPUP   =================
void drawConfirmBack() {
  // Draw the current screen in background (dimmed)
  if (mode == CONFIRM_BACK) {
    int tempMode = mode;
    mode = TIMER; // Temporarily set to TIMER to draw its background
    drawTimer();
    mode = tempMode;
  }
  
  // Semi-transparent overlay
  fill(0, 180);
  rect(0, 0, width, height);
  
  // Popup box
  float boxW = 280, boxH = 160;
  float boxX = (width - boxW) / 2;
  float boxY = (height - boxH) / 2;
  
  fill(40);
  stroke(100);
  strokeWeight(2);
  rect(boxX, boxY, boxW, boxH, 12);
  
  // Popup text
  textAlign(CENTER, CENTER);
  textFont(fontSmall);
  fill(255);
  text("Are you sure you want to", boxX + boxW/2, boxY + 40);
  text("go back to setup?", boxX + boxW/2, boxY + 60);
  
  // Yes/No buttons
  drawButton(confirmYes, "YES", color(255,80,80));
  drawButton(confirmNo, "NO", color(80,255,80));
  
  textAlign(CENTER, CENTER); // Reset alignment
}

// ==============   COMMON DRAWING UTILS   =============
void drawHalo(float x,float y,float d,float frac,int colRem,int colEl){
  float s = -HALF_PI;
  noFill();
  strokeWeight(12);
  stroke(colEl);  arc(x,y,d,d, s+TWO_PI*frac, s+TWO_PI);
  stroke(colRem); arc(x,y,d,d, s,            s+TWO_PI*frac);
}
void drawTriangle(Rectangle r, int c) { drawTriangle(r, c, false); }
void drawTriangle(Rectangle r, int c, boolean down){
  pushMatrix();
  translate(r.x + r.w/2, r.y + r.h/2);
  noStroke(); fill(c);
  if(down) rotate(PI);
  triangle(-r.w/2, r.h/2, 0, -r.h/2, r.w/2, r.h/2);
  popMatrix();
}
void drawButton(Rectangle r, String lbl, int c){
  noStroke(); fill(c); rect(r.x, r.y, r.w, r.h, 8);
  fill(0); textFont(fontSmall); text(lbl, r.x + r.w/2, r.y + r.h/2);
}

// =================   INPUT HANDLING   ===============
void mouseClicked(){
  switch(mode){
    case SETUP:
      // Handle clicks on the study minutes input box
      if (over(minutesInputBox)) {
        isMinutesInputActive = !isMinutesInputActive;
        if (isMinutesInputActive) {
          typedMinutesString = ""; // Clear string when activating input
        } else {
          applyTypedMinutes(); // Apply typed value when deactivating
        }
      }
      // Clicked elsewhere while an input was active
      else if (isMinutesInputActive) {
        applyTypedMinutes();
        isMinutesInputActive = false;
      }
      // Study time Hour, Minute, Second up/down arrows
      else if(over(hrUp))    adjustSession(3600); // Adjust by 1 hour
      else if(over(hrDown)) adjustSession(-3600); // Adjust by 1 hour
      else if(over(mnUp))    adjustSession(60); // Adjust by 1 minute
      else if(over(mnDown)) adjustSession(-60); // Adjust by 1 minute
      else if(over(scUp))    adjustSession(1); // Adjust by 1 second
      else if(over(scDown)) adjustSession(-1); // Adjust by 1 second
      // Break time Minute, Second up/down arrows (Removed hour arrows)
      else if(over(brMnUp))    adjustBreak(60); // Adjust by 1 minute
      else if(over(brMnDown)) adjustBreak(-60); // Adjust by 1 minute
      else if(over(brScUp))    adjustBreak(1); // Adjust by 1 second
      else if(over(brScDown)) adjustBreak(-1); // Adjust by 1 second
      else if(over(startHit)) {
        applyTypedMinutes(); // Ensure any pending typed study input is applied
        startSession();
      }
      break;

    case TIMER:
      if(overRing(mouseX, mouseY)) running = !running;
      else if(over(backHit))      showBackConfirmation();
      else if(over(breakHit))     startBreak();
      else if(over(resetHit))     showResetConfirmation();
      break;

    case BREAK:
      if(over(breakBackHit))      showBackConfirmation();
      else if(over(endBreakHit))  endBreak();
      else if(overRing(mouseX, mouseY)) endBreak();
      break;
      
    case CONFIRM_RESET:
      if(over(confirmYes))        confirmReset();
      else if(over(confirmNo))    cancelReset();
      break;
      
    case CONFIRM_BACK:
      if(over(confirmYes))        confirmBack();
      else if(over(confirmNo))    cancelBack();
      break;
  }
}

// Handle keyboard input
void keyPressed() {
  if (mode == SETUP) {
    if (isMinutesInputActive) {
      if (key >= '0' && key <= '9') {
        if (typedMinutesString.length() < 3) { // Max 3 digits for minutes (up to 999 minutes)
          typedMinutesString += key;
        }
      } else if (key == BACKSPACE) {
        if (typedMinutesString.length() > 0) {
          typedMinutesString = typedMinutesString.substring(0, typedMinutesString.length() - 1);
        }
      } else if (key == ENTER || key == RETURN) {
        applyTypedMinutes();
        isMinutesInputActive = false;
      }
    }
  }
}

boolean over(Rectangle r){ return mouseX>=r.x && mouseX<=r.x+r.w && mouseY>=r.y && mouseY<=r.y+r.h; }
boolean overRing(float mx,float my){ return dist(mx,my,centreX,centreY) <= ringDia/2; }

// =================   TIMER LOGIC     ===============
void updateTimers(){
  int now = millis();
  if(now - lastTick >= 1000){
    lastTick = now;
    if(mode == TIMER && running){
      timeLeft = max(timeLeft-1, 0);
      if(timeLeft == 0) running = false;
    }
    else if(mode == BREAK){
      breakLeft = max(breakLeft-1, 0);
      if(breakLeft == 0) endBreak();
    }
  }
}

// =================   STATE CHANGES   ===============
void adjustSession(int d){
  // If input box was active, apply its content before adjusting with arrows
  if (isMinutesInputActive) {
    applyTypedMinutes();
  }
  // Then, adjust sessionSeconds
  sessionSeconds = constrain(sessionSeconds + d, 1, 6*3600); // Min 1 second, Max 6 hours (360 minutes)
  displayTime = sessionSeconds;  // Update display time immediately when adjusting

  // After adjustment, ensure input box is not active and typed string is clear
  // so it reflects the new sessionSeconds value.
  isMinutesInputActive = false;
  typedMinutesString = "";
}

// Function to apply typed minutes to sessionSeconds (study time)
void applyTypedMinutes() {
  if (typedMinutesString.length() > 0) {
    try {
      int minutes = Integer.parseInt(typedMinutesString);
      // Constrain minutes to a reasonable range (e.g., 1 to 360 minutes = 6 hours)
      sessionSeconds = constrain(minutes * 60, 1, 6 * 3600); // Minimum 1 second
      displayTime = sessionSeconds; // Sync display
    } catch (NumberFormatException e) {
      println("Invalid study minutes typed: " + typedMinutesString);
      // Optionally, show an error message on screen
    }
  }
  typedMinutesString = ""; // Clear string after applying
}

// Function to adjust breakSeconds (Removed typed input handling)
void adjustBreak(int d){
  breakSeconds = constrain(breakSeconds + d, 1, 60*60); // Min 1 second, Max 60 minutes (1 hour)
  displayBreakTime = breakSeconds;  // Update display time immediately when adjusting
}


void startSession(){
  timeLeft = sessionSeconds;
  displayTime = sessionSeconds;  // Sync display time
  running = true;
  lastTick = millis();
  mode = TIMER;
}
void startBreak(){
  running = false;
  breakLeft = breakSeconds;
  displayBreakTime = breakSeconds;  // Sync break display time
  lastTick = millis();
  mode = BREAK;
}
void endBreak(){
  mode = TIMER;
  running = true;
  lastTick = millis();
}
void goBackToSetup(){
  running = false;
  mode = SETUP;
  // Reset input states when going back to setup
  isMinutesInputActive = false;
  typedMinutesString = "";
}
void showResetConfirmation(){
  mode = CONFIRM_RESET;
}
void confirmReset(){
  resetTimer();
  mode = TIMER;
}
void cancelReset(){
  mode = TIMER;
}
void showBackConfirmation(){
  mode = CONFIRM_BACK;
}
void confirmBack(){
  goBackToSetup();
}
void cancelBack(){
  mode = TIMER; // Return to previous screen
}
void resetTimer(){
  timeLeft = sessionSeconds;
  displayTime = sessionSeconds;  // Sync display time on reset
  running = false;
}

// =================   GEOMETRY        ===============
class Rectangle{ float x,y,w,h; Rectangle(float _x,float _y,float _w,float _h){ x=_x; y=_y; w=_w; h=_h; } }

// global vertical positions for clarity for Study Section
final float STUDY_TITLE_Y = 50;
final float STUDY_UP_Y    = 120;  // centre of up-arrow row
final float STUDY_TEXT_Y  = 160;  // numeric time
final float STUDY_DOWN_Y  = 200;  // centre of down-arrow row
final float STUDY_INPUT_Y = 240;  // input box for study minutes

// global vertical positions for clarity for Break Section (adjusted for smaller size)
final float BREAK_TITLE_Y = 290; // Moved up
final float BREAK_UP_Y    = 330; // Moved up
final float BREAK_TEXT_Y  = 370; // Moved up
final float BREAK_DOWN_Y  = 410; // Moved up

void computeHitboxes(){
  float triW = 40, triH = 30;
  float colGap = 100;
  float startX = centreX - colGap;

  // --- Study Time Hitboxes ---
  // Hour column
  hrUp    = new Rectangle(startX - triW/2, STUDY_UP_Y    - triH/2, triW, triH);
  hrDown = new Rectangle(startX - triW/2, STUDY_DOWN_Y - triH/2, triW, triH);

  // Minute column
  float minX = centreX;
  mnUp    = new Rectangle(minX - triW/2, STUDY_UP_Y    - triH/2, triW, triH);
  mnDown = new Rectangle(minX - triW/2, STUDY_DOWN_Y - triH/2, triW, triH);

  // Second column
  float secX = centreX + colGap;
  scUp    = new Rectangle(secX - triW/2, STUDY_UP_Y    - triH/2, triW, triH);
  scDown = new Rectangle(secX - triW/2, STUDY_DOWN_Y - triH/2, triW, triH);

  // Input box for study minutes
  float inputBoxW = 120, inputBoxH = 40;
  minutesInputBox = new Rectangle(centreX - inputBoxW/2, STUDY_INPUT_Y, inputBoxW, inputBoxH);

  // --- Break Time Hitboxes ---
  // Minute column (for break)
  brMnUp    = new Rectangle(minX - triW/2, BREAK_UP_Y    - triH/2, triW, triH); // Adjusted Y to new BREAK_UP_Y
  brMnDown = new Rectangle(minX - triW/2, BREAK_DOWN_Y - triH/2, triW, triH); // Adjusted Y to new BREAK_DOWN_Y

  // Second column (for break)
  brScUp    = new Rectangle(secX - triW/2, BREAK_UP_Y    - triH/2, triW, triH); // Adjusted Y to new BREAK_UP_Y
  brScDown = new Rectangle(secX - triW/2, BREAK_DOWN_Y - triH/2, triW, triH); // Adjusted Y to new BREAK_DOWN_Y

  // Setup screen START button (positioned below both sections)
  startHit    = new Rectangle(width/2 - 80, 460, 160, 50); // Adjusted Y position
  
  // Main buttons - three side by side (for TIMER screen)
  float timerButtonW = 100, timerButtonH = 50;
  float timerButtonSpacing = 20;
  float timerGroupWidth = (3 * timerButtonW) + (2 * timerButtonSpacing);
  float timerGroupX = (width - timerGroupWidth) / 2;
  float timerButtonY = 480; // This Y position is for the TIMER/BREAK screens

  // TIMER screen buttons
  backHit     = new Rectangle(timerGroupX, timerButtonY, timerButtonW, timerButtonH);
  resetHit    = new Rectangle(timerGroupX + timerButtonW + timerButtonSpacing, timerButtonY, timerButtonW, timerButtonH);
  breakHit    = new Rectangle(timerGroupX + 2 * (timerButtonW + timerButtonSpacing), timerButtonY, timerButtonW, timerButtonH);
  
  // BREAK screen buttons - now aligned and centered as a pair
  float breakButtonW = 100, breakButtonH = 50;
  float breakButtonSpacing = 20;
  float breakGroupWidth = (2 * breakButtonW) + (1 * breakButtonSpacing);
  float breakGroupX = (width - breakGroupWidth) / 2;
  float breakButtonY = 480; // This Y position is for the TIMER/BREAK screens

  breakBackHit = new Rectangle(breakGroupX, breakButtonY, breakButtonW, breakButtonH);
  endBreakHit = new Rectangle(breakGroupX + breakButtonW + breakButtonSpacing, breakButtonY, breakButtonW, breakButtonH);
  
  // Confirmation popup buttons (already centered)
  float popupCenterX = width / 2;
  float popupCenterY = height / 2;
  confirmYes = new Rectangle(popupCenterX - 120, popupCenterY + 20, 80, 40);
  confirmNo  = new Rectangle(popupCenterX + 40,  popupCenterY + 20, 80, 40);
}
