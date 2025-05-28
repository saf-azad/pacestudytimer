/*
 * ADHD Study Timer App - Touch-Friendly Processing Sketch
 *
 * This application provides a customizable study timer with integrated short breaks,
 * designed with a touch-friendly interface. It features:
 * - Adjustable study durations (hours, minutes, seconds)
 * - Adjustable break durations (minutes, seconds)
 * - Numeric time display positioned between adjustment arrows for clarity
 * - Smooth animation for time transitions
 * - Confirmation popups for reset and back actions
 * - Text input for precise study duration setting (in minutes)
 *
 * Layout Notes:
 * - Numeric time (HH:MM:SS) is centered between the up/down adjustment triangles.
 * - Arrow buttons are kept equidistant.
 * - START button repositioned for consistent spacing.
 *
 * Fixes & Improvements from previous versions:
 * - Centered the BACK, RESET, and BREAK buttons on the TIMER screen.
 * - Introduced a dedicated hitbox for the BACK button on the BREAK screen (`breakBackHit`)
 * for correct alignment with the END BREAK button.
 * - Aligned BACK and END BREAK buttons on the BREAK screen as a centered pair.
 * - Re-enabled hour and second adjustment triangles for study time.
 * - Synchronized the "Total Minutes" text input for study time with arrow adjustments;
 * typed input now correctly updates the main HH:MM:SS display.
 * - Consolidated setup screen layout to accommodate both study and break customization.
 * - Break time input simplified: hour adjustment arrows and "Total Minutes" input field
 * were removed. Break duration is now adjusted solely via minute and second arrows.
 * - Removed 'final' keyword from 'breakSeconds' to allow dynamic assignment and customization.
 */

// --- APPLICATION MODES ---
final int SETUP = 0;
final int TIMER = 1;
final int BREAK = 2;
final int CONFIRM_RESET = 3;
final int CONFIRM_BACK = 4;
int mode = SETUP;

// --- SESSION SETTINGS ---
int sessionSeconds = 25 * 60;   // Default 25-minute study session
int timeLeft = sessionSeconds;
int breakSeconds = 5 * 60;      // Default 5-minute break
int breakLeft = breakSeconds;

boolean running = false;
int lastTick = 0;

// --- SMOOTH ANIMATION SETTINGS ---
float displayTime = sessionSeconds;     // Smooth interpolated time for study display
float displayBreakTime = breakSeconds;  // Smooth interpolated time for break display
final float GLIDE_SPEED = 0.05;         // Animation speed (e.g., 0.01 = slow, 0.1 = fast)

// --- UI FONTS ---
PFont fontLarge, fontSmall;

// --- HALO GEOMETRY ---
float centreX, centreY, ringDia;

// --- UI HITBOXES ---
// Study time adjustment arrows
Rectangle hrUp, hrDown, mnUp, mnDown, scUp, scDown;
// Break time adjustment arrows (minutes and seconds only)
Rectangle brMnUp, brMnDown, brScUp, brScDown;

// Main screen buttons
Rectangle startHit, breakHit, resetHit, backHit; // backHit is for TIMER screen
Rectangle breakBackHit, endBreakHit;             // breakBackHit for BREAK screen

// Confirmation popup buttons
Rectangle confirmYes, confirmNo;

// Study time text input
String typedMinutesString = "";         // Stores text typed for study time
boolean isMinutesInputActive = false;   // True if study input field is active
Rectangle minutesInputBox;              // Hitbox for the study input field

void settings() {
  // Use settings() for size() and smooth() for better practice in Processing 3+
  size(400, 600);
  smooth(); // Call smooth here
}

void setup() {
  // REMOVED: smooth(); // No need to be here if it's in settings()

  centreX = width / 2.0;
  centreY = height / 2.0 - 40; // Center Y for the halo, not setup screen layout.
  ringDia = 300;

  fontLarge = createFont("Arial", 48);
  fontSmall = createFont("Arial", 18);

  computeHitboxes(); // Initialize all UI element hitboxes
}

void draw() {
  // State machine for drawing different screens
  switch (mode) {
    case SETUP:
      drawSetup();
      break;
    case TIMER:
      drawTimer();
      break;
    case BREAK:
      drawBreak();
      break;
    case CONFIRM_RESET:
      drawConfirmReset();
      break;
    case CONFIRM_BACK:
      drawConfirmBack();
      break;
  }
  updateTimers(); // Update elapsed time regardless of screen
}

// ============================= SETUP SCREEN =============================
void drawSetup() {
  background(0);
  textAlign(CENTER, CENTER);
  textFont(fontSmall);
  fill(255);

  // --- Study Duration Section ---
  text("Set study duration", centreX, STUDY_TITLE_Y);

  // Study time adjustment triangles (cyan)
  drawTriangle(hrUp, color(0, 220, 255));
  drawTriangle(hrDown, color(0, 220, 255), true);
  drawTriangle(mnUp, color(0, 220, 255));
  drawTriangle(mnDown, color(0, 220, 255), true);
  drawTriangle(scUp, color(0, 220, 255));
  drawTriangle(scDown, color(0, 220, 255), true);

  // Display current session time (HH:MM:SS)
  int hrs = sessionSeconds / 3600;
  int mins = (sessionSeconds % 3600) / 60;
  int secs = sessionSeconds % 60;
  textFont(fontLarge);
  fill(255, 50, 240); // Pinkish color for time display
  text(nf(hrs, 2) + ":" + nf(mins, 2) + ":" + nf(secs, 2), centreX, STUDY_TEXT_Y);

  // Draw study minutes input box
  noStroke();
  fill(isMinutesInputActive ? color(60) : color(30)); // Highlight when active
  rect(minutesInputBox.x, minutesInputBox.y, minutesInputBox.w, minutesInputBox.h, 8);

  textFont(fontSmall);
  fill(180);
  text("Total Minutes:", minutesInputBox.x - 60, minutesInputBox.y + minutesInputBox.h / 2);

  textFont(fontLarge); // Use large font for input numbers
  fill(255);
  if (isMinutesInputActive) {
    // Blinking cursor for active input field
    text(typedMinutesString + ((frameCount / 30) % 2 == 0 ? "|" : ""),
      minutesInputBox.x + minutesInputBox.w / 2, minutesInputBox.y + minutesInputBox.h / 2);
  } else {
    // Display current sessionSeconds in minutes when not active
    text(str(sessionSeconds / 60), minutesInputBox.x + minutesInputBox.h / 2, minutesInputBox.y + minutesInputBox.h / 2);
  }

  // --- Break Duration Section ---
  textFont(fontSmall);
  fill(255);
  text("Set break duration", centreX, BREAK_TITLE_Y);

  // Break time adjustment triangles (minutes and seconds only, cyan)
  drawTriangle(brMnUp, color(0, 220, 255));
  drawTriangle(brMnDown, color(0, 220, 255), true);
  drawTriangle(brScUp, color(0, 220, 255));
  drawTriangle(brScDown, color(0, 220, 255), true);

  // Display current break time (HH:MM:SS - hours will be 00)
  hrs = breakSeconds / 3600;
  mins = (breakSeconds % 3600) / 60;
  secs = breakSeconds % 60;
  textFont(fontLarge);
  fill(255, 50, 240); // Pinkish color for time display
  text(nf(hrs, 2) + ":" + nf(mins, 2) + ":" + nf(secs, 2), centreX, BREAK_TEXT_Y);

  // START button
  drawButton(startHit, "START", color(50, 255, 100));
}

// ============================= TIMER SCREEN =============================
void drawTimer() {
  background(0);

  // Smooth interpolation for the timer display (gliding effect)
  displayTime = lerp(displayTime, timeLeft, GLIDE_SPEED);
  float frac = displayTime / sessionSeconds; // Fraction of time remaining
  drawHalo(centreX, centreY, ringDia, frac, color(0, 200, 255), color(40)); // Blue halo

  // Display the smoothly animated time (minutes and seconds)
  int displayMinutes = (int)(displayTime / 60);
  int displaySeconds = (int)(displayTime % 60);

  textFont(fontLarge);
  fill(255);
  text(nf(displayMinutes, 2) + ":" + nf(displaySeconds, 2), centreX, centreY);

  // Pause/resume instruction text
  textFont(fontSmall);
  fill(120);
  text(running ? "Tap ring to pause" : "Tap ring to resume", centreX, centreY + 50);

  // Main control buttons (BACK, RESET, BREAK)
  drawButton(backHit, "BACK", color(150, 150, 150));
  drawButton(resetHit, "RESET", color(0, 255, 180));
  drawButton(breakHit, "BREAK", color(255, 100, 0));
}

// ============================= BREAK SCREEN =============================
void drawBreak() {
  background(0);

  // Smooth interpolation for the break timer display
  displayBreakTime = lerp(displayBreakTime, breakLeft, GLIDE_SPEED);
  float frac = displayBreakTime / breakSeconds; // Fraction of break time remaining
  drawHalo(centreX, centreY, ringDia, frac, color(255, 100, 0), color(40)); // Orange halo

  // Display the smoothly animated break time (minutes and seconds)
  int displayMinutes = (int)(displayBreakTime / 60);
  int displaySeconds = (int)(displayBreakTime % 60);

  textFont(fontLarge);
  fill(255);
  text(nf(displayMinutes, 2) + ":" + nf(displaySeconds, 2), centreX, centreY);

  // Break screen control buttons (BACK, END BREAK)
  drawButton(breakBackHit, "BACK", color(150, 150, 150));
  drawButton(endBreakHit, "END BREAK", color(0, 255, 180));

  textFont(fontSmall);
  fill(120);
  text("Time for a break!", centreX, centreY + 50); // General break message
}

// ========================= CONFIRMATION POPUPS =========================
void drawConfirmReset() {
  // Draw the current timer screen in background (dimmed)
  drawTimer();

  // Semi-transparent overlay to dim the background
  fill(0, 180);
  rect(0, 0, width, height);

  // Popup box
  float boxW = 280, boxH = 160;
  float boxX = (width - boxW) / 2;
  float boxY = (height - boxH) / 2;

  fill(40);
  stroke(100);
  strokeWeight(2);
  rect(boxX, boxY, boxW, boxH, 12); // Rounded corners

  // Popup text
  textAlign(CENTER, CENTER);
  textFont(fontSmall);
  fill(255);
  text("Are you sure you want to", boxX + boxW / 2, boxY + 40);
  text("reset your timer?", boxX + boxW / 2, boxY + 60);

  // Yes/No buttons for confirmation
  drawButton(confirmYes, "YES", color(255, 80, 80)); // Red for Yes (destructive)
  drawButton(confirmNo, "NO", color(80, 255, 80));   // Green for No (safe)

  textAlign(CENTER, CENTER); // Reset alignment for consistency
}

void drawConfirmBack() {
  // Draw the current screen in background (dimmed)
  // Temporarily switch mode to TIMER to draw its background if currently in CONFIRM_BACK
  int tempMode = mode;
  mode = TIMER;
  drawTimer();
  mode = tempMode;

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
  text("Are you sure you want to", boxX + boxW / 2, boxY + 40);
  text("go back to setup?", boxX + boxW / 2, boxY + 60);

  // Yes/No buttons for confirmation
  drawButton(confirmYes, "YES", color(255, 80, 80));
  drawButton(confirmNo, "NO", color(80, 255, 80));

  textAlign(CENTER, CENTER); // Reset alignment
}

// ========================= COMMON DRAWING UTILS =========================
// Draws a circular halo with a remaining time segment (colRem) and elapsed time segment (colEl)
void drawHalo(float x, float y, float d, float frac, int colRem, int colEl) {
  float startAngle = -HALF_PI; // Start from the top
  noFill();
  strokeWeight(12);

  // Draw elapsed portion
  stroke(colEl);
  arc(x, y, d, d, startAngle + TWO_PI * frac, startAngle + TWO_PI);
  // Draw remaining portion
  stroke(colRem);
  arc(x, y, d, d, startAngle, startAngle + TWO_PI * frac);
}

// Overloaded method to draw an upward-pointing triangle
void drawTriangle(Rectangle r, int c) {
  drawTriangle(r, c, false);
}

// Draws a triangle (up or down) within a given rectangle hitbox
void drawTriangle(Rectangle r, int c, boolean down) {
  pushMatrix();
  translate(r.x + r.w / 2, r.y + r.h / 2); // Translate to center of hitbox
  noStroke();
  fill(c);
  if (down) rotate(PI); // Rotate 180 degrees for a down-pointing triangle
  triangle(-r.w / 2, r.h / 2, 0, -r.h / 2, r.w / 2, r.h / 2);
  popMatrix();
}

// Draws a rectangular button with text label
void drawButton(Rectangle r, String lbl, int c) {
  noStroke();
  fill(c);
  rect(r.x, r.y, r.w, r.h, 8); // Rounded rectangle
  fill(0); // Black text
  textFont(fontSmall);
  text(lbl, r.x + r.w / 2, r.y + r.h / 2); // Centered text
}

// ============================= INPUT HANDLING ===========================
void mouseClicked() {
  switch (mode) {
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
      // Clicked elsewhere while an input was active (deactivate and apply)
      else if (isMinutesInputActive) {
        applyTypedMinutes();
        isMinutesInputActive = false;
      }
      // Study time adjustment arrows
      else if (over(hrUp)) adjustSession(3600); // Adjust by 1 hour
      else if (over(hrDown)) adjustSession(-3600); // Adjust by 1 hour
      else if (over(mnUp)) adjustSession(60); // Adjust by 1 minute
      else if (over(mnDown)) adjustSession(-60); // Adjust by 1 minute
      else if (over(scUp)) adjustSession(1); // Adjust by 1 second
      else if (over(scDown)) adjustSession(-1); // Adjust by 1 second
      // Break time adjustment arrows (minutes and seconds only)
      else if (over(brMnUp)) adjustBreak(60); // Adjust by 1 minute
      else if (over(brMnDown)) adjustBreak(-60); // Adjust by 1 minute
      else if (over(brScUp)) adjustBreak(1); // Adjust by 1 second
      else if (over(brScDown)) adjustBreak(-1); // Adjust by 1 second
      else if (over(startHit)) {
        applyTypedMinutes(); // Ensure any pending typed study input is applied
        startSession();
      }
      break;

    case TIMER:
      if (overRing(mouseX, mouseY)) running = !running; // Toggle pause/resume
      else if (over(backHit)) showBackConfirmation();
      else if (over(breakHit)) startBreak();
      else if (over(resetHit)) showResetConfirmation();
      break;

    case BREAK:
      if (over(breakBackHit)) showBackConfirmation();
      else if (over(endBreakHit)) endBreak();
      else if (overRing(mouseX, mouseY)) endBreak(); // Tap ring to end break early
      break;

    case CONFIRM_RESET:
      if (over(confirmYes)) confirmReset();
      else if (over(confirmNo)) cancelReset();
      break;

    case CONFIRM_BACK:
      if (over(confirmYes)) confirmBack();
      else if (over(confirmNo)) cancelBack();
      break;
  }
}

// Handles keyboard input for the study minutes text field
void keyPressed() {
  if (mode == SETUP && isMinutesInputActive) {
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

// Checks if mouse is over a given rectangle hitbox
boolean over(Rectangle r) {
  return mouseX >= r.x && mouseX <= r.x + r.w && mouseY >= r.y && mouseY <= r.y + r.h;
}

// Checks if mouse is over the main circular timer ring
boolean overRing(float mx, float my) {
  return dist(mx, my, centreX, centreY) <= ringDia / 2;
}

// ============================= TIMER LOGIC ==============================
void updateTimers() {
  int now = millis();
  if (now - lastTick >= 1000) { // Check every second
    lastTick = now;
    if (mode == TIMER && running) {
      timeLeft = max(timeLeft - 1, 0); // Decrement, don't go below zero
      if (timeLeft == 0) running = false; // Stop timer when it reaches zero
    } else if (mode == BREAK) {
      breakLeft = max(breakLeft - 1, 0); // Decrement break timer
      if (breakLeft == 0) endBreak();    // End break when it reaches zero
    }
  }
}

// =========================== STATE CHANGES ============================
// Adjusts the session (study) duration in seconds
void adjustSession(int d) {
  // If input box was active, apply its content before adjusting with arrows
  if (isMinutesInputActive) {
    applyTypedMinutes();
  }
  // Then, adjust sessionSeconds
  sessionSeconds = constrain(sessionSeconds + d, 1, 6 * 3600); // Min 1 sec, Max 6 hours
  displayTime = sessionSeconds; // Update display time immediately for responsiveness

  // After adjustment, ensure input box is not active and typed string is clear
  isMinutesInputActive = false;
  typedMinutesString = "";
}

// Applies the typed minutes string to sessionSeconds (study time)
void applyTypedMinutes() {
  if (typedMinutesString.length() > 0) {
    try {
      int minutes = Integer.parseInt(typedMinutesString);
      // Constrain minutes to a reasonable range (e.g., 1 to 360 minutes = 6 hours)
      sessionSeconds = constrain(minutes * 60, 1, 6 * 3600); // Minimum 1 second
      displayTime = sessionSeconds; // Sync display
    } catch (NumberFormatException e) {
      println("Invalid study minutes typed: " + typedMinutesString);
      // Optionally: display an error message to the user
    }
  }
  typedMinutesString = ""; // Clear string after applying
}

// Adjusts the break duration in seconds
void adjustBreak(int d) {
  breakSeconds = constrain(breakSeconds + d, 1, 60 * 60); // Min 1 sec, Max 60 minutes (1 hour)
  displayBreakTime = breakSeconds; // Update display time immediately
}

// Initiates a study session
void startSession() {
  timeLeft = sessionSeconds;      // Set current time to full session duration
  displayTime = sessionSeconds;   // Sync display time
  running = true;                 // Start the timer
  lastTick = millis();            // Record start time for countdown
  mode = TIMER;                   // Switch to TIMER screen
}

// Initiates a break session
void startBreak() {
  running = false;                // Pause study timer
  breakLeft = breakSeconds;       // Set current break time to full break duration
  displayBreakTime = breakSeconds; // Sync break display time
  lastTick = millis();            // Record start time for break countdown
  mode = BREAK;                   // Switch to BREAK screen
}

// Ends the current break session
void endBreak() {
  mode = TIMER;                   // Return to TIMER screen
  running = true;                 // Resume study timer
  lastTick = millis();            // Record start time for study countdown
}

// Returns to the setup screen
void goBackToSetup() {
  running = false;                // Stop any running timer
  mode = SETUP;                   // Switch to SETUP screen
  // Reset input states when returning to setup
  isMinutesInputActive = false;
  typedMinutesString = "";
}

// Shows the reset confirmation popup
void showResetConfirmation() {
  mode = CONFIRM_RESET;
}

// Confirms and performs timer reset
void confirmReset() {
  resetTimer();
  mode = TIMER; // Return to TIMER screen
}

// Cancels the reset action
void cancelReset() {
  mode = TIMER; // Return to TIMER screen
}

// Shows the back confirmation popup
void showBackConfirmation() {
  mode = CONFIRM_BACK;
}

// Confirms and performs going back to setup
void confirmBack() {
  goBackToSetup();
}

// Cancels the back action
void cancelBack() {
  mode = TIMER; // Return to previous screen (TIMER)
}

// Resets the study timer to its initial session duration
void resetTimer() {
  timeLeft = sessionSeconds;
  displayTime = sessionSeconds; // Sync display time on reset
  running = false; // Stop the timer
}

// ============================== GEOMETRY CLASSES ==============================
// Simple class to represent a rectangular area for hit detection
class Rectangle {
  float x, y, w, h;
  Rectangle(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
  }
}

// --- GLOBAL VERTICAL POSITIONS FOR UI ELEMENTS (SETUP SCREEN) ---
// Study Section
final float STUDY_TITLE_Y = 50;
final float STUDY_UP_Y = 120;     // Y-coordinate for the center of the UP arrow row
final float STUDY_TEXT_Y = 160;   // Y-coordinate for the numeric time display
final float STUDY_DOWN_Y = 200;   // Y-coordinate for the center of the DOWN arrow row
final float STUDY_INPUT_Y = 240;  // Y-coordinate for the study minutes input box

// Break Section (adjusted for compactness)
final float BREAK_TITLE_Y = 290;
final float BREAK_UP_Y = 330;
final float BREAK_TEXT_Y = 370;
final float BREAK_DOWN_Y = 410;

// Computes and initializes all UI element hitboxes based on defined layout constants
void computeHitboxes() {
  float triW = 40, triH = 30; // Triangle (arrow) width and height
  float colGap = 100;         // Horizontal gap between time columns (Hour, Minute, Second)
  float startX = centreX - colGap; // X-coordinate for the Hour column (leftmost)

  // --- Study Time Hitboxes ---
  hrUp = new Rectangle(startX - triW / 2, STUDY_UP_Y - triH / 2, triW, triH);
  hrDown = new Rectangle(startX - triW / 2, STUDY_DOWN_Y - triH / 2, triW, triH);

  float minX = centreX; // X-coordinate for the Minute column (center)
  mnUp = new Rectangle(minX - triW / 2, STUDY_UP_Y - triH / 2, triW, triH);
  mnDown = new Rectangle(minX - triW / 2, STUDY_DOWN_Y - triH / 2, triW, triH);

  float secX = centreX + colGap; // X-coordinate for the Second column (rightmost)
  scUp = new Rectangle(secX - triW / 2, STUDY_UP_Y - triH / 2, triW, triH);
  scDown = new Rectangle(secX - triW / 2, STUDY_DOWN_Y - triH / 2, triW, triH);

  // Input box for study minutes
  float inputBoxW = 120, inputBoxH = 40;
  minutesInputBox = new Rectangle(centreX - inputBoxW / 2, STUDY_INPUT_Y, inputBoxW, inputBoxH);

  // --- Break Time Hitboxes ---
  // Minute column (for break)
  brMnUp = new Rectangle(minX - triW / 2, BREAK_UP_Y - triH / 2, triW, triH);
  brMnDown = new Rectangle(minX - triW / 2, BREAK_DOWN_Y - triH / 2, triW, triH);

  // Second column (for break)
  brScUp = new Rectangle(secX - triW / 2, BREAK_UP_Y - triH / 2, triW, triH);
  brScDown = new Rectangle(secX - triW / 2, BREAK_DOWN_Y - triH / 2, triW, triH);

  // Setup screen START button (positioned below both study and break sections)
  startHit = new Rectangle(width / 2 - 80, 460, 160, 50);

  // --- Main control buttons (TIMER and BREAK screens) ---
  float timerButtonW = 100, timerButtonH = 50; // Button dimensions
  float timerButtonSpacing = 20;               // Spacing between buttons
  float timerGroupWidth = (3 * timerButtonW) + (2 * timerButtonSpacing);
  float timerGroupX = (width - timerGroupWidth) / 2; // Calculate starting X for centered group
  final float TIMER_BUTTON_Y = 480;             // Y-coordinate for all main timer/break buttons

  // TIMER screen buttons (three side-by-side)
  backHit = new Rectangle(timerGroupX, TIMER_BUTTON_Y, timerButtonW, timerButtonH);
  resetHit = new Rectangle(timerGroupX + timerButtonW + timerButtonSpacing, TIMER_BUTTON_Y, timerButtonW, timerButtonH);
  breakHit = new Rectangle(timerGroupX + 2 * (timerButtonW + timerButtonSpacing), TIMER_BUTTON_Y, timerButtonW, timerButtonH);

  // BREAK screen buttons (two side-by-side, centered)
  float breakButtonW = 100, breakButtonH = 50;
  float breakButtonSpacing = 20;
  float breakGroupWidth = (2 * breakButtonW) + (1 * breakButtonSpacing);
  float breakGroupX = (width - breakGroupWidth) / 2;
  // Use the same Y as TIMER buttons for consistency
  breakBackHit = new Rectangle(breakGroupX, TIMER_BUTTON_Y, breakButtonW, breakButtonH);
  endBreakHit = new Rectangle(breakGroupX + breakButtonW + breakButtonSpacing, TIMER_BUTTON_Y, breakButtonW, breakButtonH);

  // Confirmation popup buttons (centered below popup text)
  float popupCenterX = width / 2;
  float popupCenterY = height / 2;
  confirmYes = new Rectangle(popupCenterX - 120, popupCenterY + 20, 80, 40);
  confirmNo = new Rectangle(popupCenterX + 40, popupCenterY + 20, 80, 40);
}
