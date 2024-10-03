Fish[] fishes;  // Array to hold multiple Fish objects
boolean debug = false; // Debug mode toggle
int animal; // Variable to switch between different animal behaviors
int numFishes = 6;  // Number of fishes you want to create

// Variables for ocean drawing
float noiseScale = 0.02; // Scale of the noise
float timeOffset = 0; // Offset for animation over time

// Food variables
PVector foodPosition; // Position of the food

void setup() {
    fullScreen(P2D);
    frameRate(60);   // Set the frame rate to 60 frames per second

    // Initialize the fishes array and create each fish
    fishes = new Fish[numFishes];
    for (int i = 0; i < numFishes; i++) {
        // Randomize the initial position for each fish
        fishes[i] = new Fish(new PVector(random(width), random(height)));
    }
}

void draw() {
    drawOcean(); // Draw the ocean background
    
     if (debug) {
      // Define the danger zone buffer size
      float dangerZone = 300;
    
      // Set the color for the danger zone
      fill(100, 0, 0, 80);  // Semi-transparent red for the danger zone
      noStroke();
    
      // Draw rectangles to mark the danger zone on all edges
      // Top danger zone
      rect(0, 0, width, dangerZone);
      // Bottom danger zone
      rect(0, height - dangerZone, width, dangerZone);
      // Left danger zone
      rect(0, 0, dangerZone, height);
      // Right danger zone
      rect(width - dangerZone, 0, dangerZone, height);
    }

    // Handle the fish movement and respawning
    for (int i = 0; i < numFishes; i++) {
        fishes[i].resolve(fishes);
        fishes[i].display(debug);

        // Get the position of the fish head
        PVector headPos = fishes[i].spine.joints.get(0);

        // Check if the fish has naturally exited the screen
        if (!fishes[i].isEnteringSafeZone && (headPos.x < -200 || headPos.x > width + 200 || headPos.y < -200 || headPos.y > height + 200)) {
            
            // Spawn a new fish outside the screen
            PVector spawnPos;
            int edge = int(random(4));  // Randomly choose an edge (0: left, 1: right, 2: top, 3: bottom)

            switch (edge) {
                case 0: // Left
                    spawnPos = new PVector(-300, random(height));
                    break;
                case 1: // Right
                    spawnPos = new PVector(width + 300, random(height));
                    break;
                case 2: // Top
                    spawnPos = new PVector(random(width), -300);
                    break;
                case 3: // Bottom
                    spawnPos = new PVector(random(width), height + 300);
                    break;
                default:
                    spawnPos = new PVector(random(-300, width + 300), random(-300, height + 300));
                    break;
            }

            // Replace the exiting fish with a new fish spawned outside the screen
            fishes[i] = new Fish(spawnPos);
        }
        
    }
}

void drawOcean() {
    // Set background color to a darker ocean color
    background(0, 46, 71); // Dark ocean color
    noStroke();

    // Loop through the canvas to draw light spots
    for (int x = 0; x < width + 320; x += 160) {
        for (int y = 0; y < height + 320; y += 160) {
            // Get noise value for this position
            float n = noise(x * noiseScale, y * noiseScale, timeOffset);
            
            // Map the noise value directly to the blue component (0 to 255)
            float blueComponent = map(n, 0, 1, 0, 150); // Directly map noise to blue component
            
            // Set fill color with the mapped blue component and some transparency
            fill(0, 0, blueComponent, 80); // Fill with varying blue, keeping red and green at 0
            
            // Draw a large ellipse (light spot) at this position
            ellipse(x, y, 320 * 2, 320 * 2); // Large ellipse for soft light effect
        }
    }
    
    // Update the time offset to animate the noise
    timeOffset += 0.005; // Change speed of animation here
}

void mousePressed() {
    // Spawn food at mouse position when clicked
    foodPosition = new PVector(mouseX, mouseY);
    for (int i = 0; i < numFishes; i++) {
      fishes[i].followClick = true;
    }
}
