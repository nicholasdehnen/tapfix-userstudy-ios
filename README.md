# TapFix User Study Application

## App Description
This is a test application designed for a user study evaluating a unique typo correction method, TapFix, against the two baseline methods present in Apple iOS. The app introduces users to the TapFix method, presents them with sentences containing typographical errors and prompts them to correct the mistakes. Throughout the study, it collects performance data to analyze how effectively users can identify and fix typos.

## Repository Overview

This repository contains the main application source code, as well as all supporting resources (images and other assets).

#### TapFix/
This folder contains the core app implementation, which is implemented in Swift/SwiftUI and follows the Model-View-ViewModel pattern. It is organized into several subdirectories:

- **models/**  
  Contains data model definitions that structure:
  - Test results and user study data.
  - Data representing sentences with typos and their corrections.
  - Enums and structs to ensure consistent data handling.

- **views/**  
  Contains SwiftUI view files that define the user interface, including:
  - Introductory screens and test setup interfaces.
  - Interactive views for performing typo corrections and visualizing changes.
  - Specialized views for warmup tasks, result display, and error handling.

- **viewmodels/**  
  Contains Swift files that manage application state and business logic, including:
  - Coordinating communication between the model and view layers.
  - Handling typo correction tasks and test progression.
  - Initial processing and validation of test results.

- **classes/**  
  Contains utility and helper classes that provide:
  - Core functionality such as view control and error handling.
  - Custom logging, text processing, and string manipulation.
  - Extensions to enhance Swift and UI component functionality.

- **Assets.xcassets/**  
  Contains visual resources for the app, including:
  - App icons, accent colors, and other image assets.
  - Configuration files that define how these assets are used by the app.

### TapFix.xcodeproj/
Contains the Xcode project configuration files and build settings necessary for compiling, building, and running the TapFix iOS application.

## Building the Application
Note: A macOS-based device is required to build the TapFix application.
1. **Clone the Repository**  
   Open a terminal and run:
   ```sh
   git clone https://github.com/nicholasdehnen/tapfix-userstudy-ios.git
   ```

2. **Open in Xcode**  
   Navigate to the cloned folder and open the `TapFix.xcodeproj` file by double-clicking it or using Xcode’s **File > Open...** menu.

3. **Build and Run**  
   Select the desired simulator or connected iOS device, then build (⌘B) and run (⌘R) the project from Xcode.
