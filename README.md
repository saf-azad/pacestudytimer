# pacestudytimer
This is a small timer project I have been working on. A study timer that is directed to individuals with ADHD or struggle with overstimulation while studying.
## Features

* **Customizable Study Durations**: Set your study sessions precisely with adjustments for hours, minutes, and seconds.
* **Customizable Break Durations**: Define your short breaks in minutes and seconds.
* **Intuitive UI**: Numeric time display is centrally located between easily accessible up/down arrow controls.
* **Smooth Animations**: Enjoy a gliding effect for time transitions.
* **Confirmation Prompts**: Safely reset your timer or navigate back to the setup screen with clear confirmation popups.
* **Direct Time Input**: For study sessions, directly type in the total minutes for quick setup.
* **Pause/Resume**: Tap the main timer ring to pause or resume your session.
* **Break Integration**: Seamlessly transition into a break, with an option to end it early.


To run this Processing sketch:

1.  **Download Processing**: If you don't have it, download and install the [Processing Development Environment (PDE)](https://processing.org/download/).
2.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/](https://github.com/)[YOUR_USERNAME]/ADHD-Study-Timer.git
    ```
3.  **Open the Sketch**:
    * Open the Processing IDE.
    * Go to `File > Open...` and navigate to the `ADHD-Study-Timer/src/` directory.
    * Select `ADHD_Study_Timer.pde` and click "Open".
4.  **Run**: Click the "Run" button (the ▶ icon) in the Processing IDE.

## Usage

* **Setup Screen**:
    * Use the **▲ / ▼** arrows to adjust study duration (HH:MM:SS) and break duration (MM:SS).
    * Tap the "Total Minutes" box under "Set study duration" to activate text input for study time. Type your desired minutes and press Enter or click outside the box to apply.
    * Click "START" to begin your study session.
* **Timer Screen**:
    * The large halo and numbers display your remaining study time.
    * Tap the **halo ring** to pause or resume the timer.
    * "BACK": Go back to the setup screen (requires confirmation if timer is running).
    * "RESET": Reset the current study timer to its initial duration (requires confirmation).
    * "BREAK": Start a short break.
* **Break Screen**:
    * The orange halo displays your remaining break time.
    * "BACK": Go back to the study timer (requires confirmation).
    * "END BREAK": End the break early and resume the study timer. You can also tap the halo ring to end the break early.

## Contributing

Contributions are welcome! If you have suggestions for improvements or find bugs, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the pacestudytimer/LICENSE file for details.

---
