// Bloopy lil dude
class Fish {
    Chain spine;
    ArrayList<Ripple> ripples = new ArrayList<Ripple>();  // List of ripples

    color bodyColor = color(58, 124, 165);
    color finColor = color(129, 195, 215);

    // Scaling factor to shrink everything by 5
    float scaleFactor = 0.35;
    float speed = 0.7;
    int rippleSpawnCounter = 0;
    int rippleSpace = 10; // Pause between ripples

    // Lifetime attributes
    float lifetime;          // Lifetime in frames
    float age = 0;          // Age of the fish in frames
    boolean isEnteringSafeZone = true; // Flag to check if the fish is entering the safe zone
    PVector safeZoneTarget; // Target for mouse pos within safe zone
    
    float dangerZone = 300;  // Distance from the border that defines the danger zone
    float returnStrength = 0.11;  // Strength of adjustment to return to the safe zone
    
    boolean followClick = false; // Is currently following click of user instead of normal behaviour

    // Width of the fish at each vertebra
    float[] bodyWidth = {
        68 * scaleFactor, 
        81 * scaleFactor, 
        84 * scaleFactor, 
        83 * scaleFactor, 
        77 * scaleFactor, 
        64 * scaleFactor, 
        51 * scaleFactor, 
        38 * scaleFactor, 
        32 * scaleFactor, 
        19 * scaleFactor
    };

    // Virtual mouse movement variables
    PVector virtualMousePos;  // Position of the virtual mouse that the fish will follow
    PVector virtualMouseDir;  // Direction of virtual mouse movement
    float moveSpeed = 1.5;    // Speed of virtual mouse movement
    float minDistance = 80;    // Minimum distance the virtual mouse will stay away from the fish
    float avoidDistance = 100;  // Distance to avoid other fish

    Fish(PVector origin) {
        // 12 segments, first 10 for body, last 2 for caudal fin
        spine = new Chain(origin, 12, int(64 * scaleFactor), PI/8);
        
        // Randomize body and fin colors using HSB mode
        colorMode(HSB, 360, 100, 100);
        float randomHue = random(360);  // Randomize hue (0-360)
        float randomSaturation = random(60, 100);  // Randomize saturation (60-100) for vibrant colors
        float bodyBrightness = random(40, 70);  // Keep the body color's brightness moderate (40-70)
        float finBrightness = min(bodyBrightness + 30, 100);  // Make the fin color brighter (but max is 100)
        bodyColor = color(randomHue, randomSaturation, bodyBrightness);  // Random body color
        finColor = color(randomHue, randomSaturation, finBrightness);    // Brighter fin color
        colorMode(RGB, 255);  // Reset to default RGB mode

        // Initialize virtual mouse position and direction
        virtualMousePos = PVector.add(origin, new PVector(random(-200, 200), random(-200, 200)));
        virtualMouseDir = PVector.fromAngle(random(TWO_PI)).setMag(moveSpeed);

        // Set random lifetime between 600 and 1200 frames (10-20 sec)
        lifetime = random(600, 1200);  
        
        // Calculate a random point within the safe zone
        float safeX = random(dangerZone, width - dangerZone);
        float safeY = random(dangerZone, height - dangerZone);
        safeZoneTarget = new PVector(safeX, safeY);  // Random target in the safe zone
    }

    // Resolve movement with avoidance for other fish
    void resolve(Fish[] fishes) {
        PVector headPos = spine.joints.get(0);
        age++;  // Increment the age of the fish each frame
        
        if (followClick) {
          virtualMousePos = foodPosition;
          speed = 2;
          
          // If already at food, disable
          // Check for collision with food
          if (PVector.dist(spine.joints.get(0), foodPosition) < 20) {
              // If fish hits the food, no longer follow click
              followClick = false;
          }
        }
        // normal behaviour
        else {
          speed = 0.7;
          
          // Check if the fish has reached its lifetime
          if (age >= lifetime) {
              dangerZone = -300; // this makes the fish able to exit while moving normally
          }
          
          // Enter safe zone first, then move normally
          if (isEnteringSafeZone) {
            moveToSafeZone();
          }
          else {
            normalMovement(fishes);
            // Update the virtual mouse position based on its current direction
            virtualMousePos.add(virtualMouseDir);
            
            // Constrain the virtual mouse to stay within the canvas, but allow it to approach the edges
            virtualMousePos.x = constrain(virtualMousePos.x, -200, width + 200);
            virtualMousePos.y = constrain(virtualMousePos.y, -200, height + 200);
          }
        }
        

        // Move the fish towards the virtual mouse
        PVector targetPos = PVector.add(headPos, PVector.sub(virtualMousePos, headPos).setMag(16 * scaleFactor * speed));
        spine.resolve(targetPos);
        
        // Add a new ripple at the fish's head position
        if (++rippleSpawnCounter % rippleSpace == 0) {
            ripples.add(new Ripple(headPos));
            rippleSpawnCounter = 0;
        }

        // Update existing ripples
        for (int i = ripples.size() - 1; i >= 0; i--) {
            ripples.get(i).update();
            if (!ripples.get(i).isVisible()) {
                ripples.remove(i);  // Remove the ripple if it's no longer visible
            }
        }
    }

    void moveToSafeZone() {
        // Calculate a small random offset
        float offsetX = random(-20, 20); // Adjust the range as needed
        float offsetY = random(-20, 20); // Adjust the range as needed
    
        // Update the safe zone target position gradually
        safeZoneTarget.add(new PVector(offsetX, offsetY));
    
        // Constrain the target to stay within the safe zone
        safeZoneTarget.x = constrain(safeZoneTarget.x, 300, width - 300);
        safeZoneTarget.y = constrain(safeZoneTarget.y, 300, height - 300);
    
        // Gradually move the virtual mouse position towards the target position
        virtualMousePos = PVector.lerp(virtualMousePos, safeZoneTarget, 0.1); // Adjust the 0.1 for speed of interpolation
    
        // Check if the fish has reached the safe zone
        if (PVector.dist(spine.joints.get(0), safeZoneTarget) < 50) {
            isEnteringSafeZone = false; // Stop moving towards the safe zone
            age = 0;  // Reset age after reaching the safe zone
        }
    }
    void normalMovement(Fish[] fishes) {
        PVector headPos = spine.joints.get(0);

        // Ensure the virtual mouse is never too close to the fish itself
        float distanceToFish = PVector.dist(virtualMousePos, headPos);
        if (distanceToFish < minDistance) {
            PVector escapeDir = PVector.sub(virtualMousePos, headPos).normalize().mult(minDistance);
            virtualMousePos = PVector.add(headPos, escapeDir);
        }

        // Avoid other fish
        for (Fish otherFish : fishes) {
            if (otherFish != this) {
                PVector otherHeadPos = otherFish.spine.joints.get(0);
                float distanceToOther = PVector.dist(headPos, otherHeadPos);

                if (distanceToOther < avoidDistance) {
                    // Calculate a repulsion force away from the other fish
                    PVector repulsionDir = PVector.sub(headPos, otherHeadPos).normalize();
                    float repulsionStrength = (avoidDistance - distanceToOther) / avoidDistance; // Stronger repulsion when closer
                    virtualMouseDir.add(repulsionDir.mult(repulsionStrength * 0.1));  // Adjust direction to steer away
                }
            }
        }

        // Check if the virtual mouse is in the danger zone near the left or right edges
        if (virtualMousePos.x < dangerZone) {
            virtualMouseDir.x += returnStrength; // Steer away from the edge
        } else if (virtualMousePos.x > width - dangerZone) {
            virtualMouseDir.x -= returnStrength; // Steer away from the edge
        }

        // Check if the virtual mouse is in the danger zone near the top or bottom edges
        if (virtualMousePos.y < dangerZone) {
            virtualMouseDir.y += returnStrength; // Steer away from the edge
        } else if (virtualMousePos.y > height - dangerZone) {
            virtualMouseDir.y -= returnStrength; // Steer away from the edge
        }

        // Dynamic turning to prevent straight-line movement
        if (random(1) < 0.05) {  // 5% chance to make a random turn
            virtualMouseDir.rotate(random(-PI / 4, PI / 4));  // Turn up to 45 degrees
        } else {
            virtualMouseDir.rotate(random(-PI / 100, PI / 100));  // Small turns
        }
    }

  void display(boolean debug) {
    
      // Display ripples
    for (Ripple ripple : ripples) {
      ripple.display();
    }
    
    if (debug){
       // Display the virtual mouse as a red dot
      fill(255, 0, 0);  // Set the fill color to red
      noStroke();  // No outline for the dot
      ellipse(virtualMousePos.x, virtualMousePos.y, 10, 10);  // Draw a small red dot at the virtual mouse position
    }
    
    
    strokeWeight(4 * scaleFactor);
    stroke(255);
    fill(finColor);

    // Alternate labels for shorter lines of code
    ArrayList<PVector> j = spine.joints;
    ArrayList<Float> a = spine.angles;

    // Relative angle differences are used in some hacky computation for the dorsal fin
    float headToMid1 = relativeAngleDiff(a.get(0), a.get(6));
    float headToMid2 = relativeAngleDiff(a.get(0), a.get(7));
    float headToTail = headToMid1 + relativeAngleDiff(a.get(6), a.get(11));

    // === START PECTORAL FINS ===
    pushMatrix();
    translate(getPosX(3, PI/3, 0), getPosY(3, PI/3, 0));
    rotate(a.get(2) - PI/4);
    ellipse(0, 0, 160 * scaleFactor, 64 * scaleFactor); // Right
    popMatrix();
    pushMatrix();
    translate(getPosX(3, -PI/3, 0), getPosY(3, -PI/3, 0));
    rotate(a.get(2) + PI/4);
    ellipse(0, 0, 160 * scaleFactor, 64 * scaleFactor); // Left
    popMatrix();
    // === END PECTORAL FINS ===

    // === START VENTRAL FINS ===
    pushMatrix();
    translate(getPosX(7, PI/2, 0), getPosY(7, PI/2, 0));
    rotate(a.get(6) - PI/4);
    ellipse(0, 0, 96 * scaleFactor, 32 * scaleFactor); // Right
    popMatrix();
    pushMatrix();
    translate(getPosX(7, -PI/2, 0), getPosY(7, -PI/2, 0));
    rotate(a.get(6) + PI/4);
    ellipse(0, 0, 96 * scaleFactor, 32 * scaleFactor); // Left
    popMatrix();
    // === END VENTRAL FINS ===

    // === START CAUDAL FINS ===
    beginShape();
    // "Bottom" of the fish
    for (int i = 8; i < 12; i++) {
      float tailWidth = 1.5 * headToTail * (i - 8) * (i - 8) * scaleFactor;
      curveVertex(j.get(i).x + cos(a.get(i) - PI/2) * tailWidth, j.get(i).y + sin(a.get(i) - PI/2) * tailWidth);
    }

    // "Top" of the fish
    for (int i = 11; i >= 8; i--) {
      float tailWidth = max(-13, min(13, headToTail * 6)) * scaleFactor;
      curveVertex(j.get(i).x + cos(a.get(i) + PI/2) * tailWidth, j.get(i).y + sin(a.get(i) + PI/2) * tailWidth);
    }
    endShape(CLOSE);
    // === END CAUDAL FINS ===

    fill(bodyColor);

    // === START BODY ===
    beginShape();

    // Right half of the fish
    for (int i = 0; i < 10; i++) {
      curveVertex(getPosX(i, PI/2, 0), getPosY(i, PI/2, 0));
    }

    // Bottom of the fish
    curveVertex(getPosX(9, PI, 0), getPosY(9, PI, 0));

    // Left half of the fish
    for (int i = 9; i >= 0; i--) {
      curveVertex(getPosX(i, -PI/2, 0), getPosY(i, -PI/2, 0));
    }

    // Top of the head (completes the loop)
    curveVertex(getPosX(0, -PI/6, 0), getPosY(0, -PI/6, 0));
    curveVertex(getPosX(0, 0, 4 * scaleFactor), getPosY(0, 0, 4 * scaleFactor));
    curveVertex(getPosX(0, PI/6, 0), getPosY(0, PI/6, 0));

    // Some overlap needed because curveVertex requires extra vertices that are not rendered
    curveVertex(getPosX(0, PI/2, 0), getPosY(0, PI/2, 0));
    curveVertex(getPosX(1, PI/2, 0), getPosY(1, PI/2, 0));
    curveVertex(getPosX(2, PI/2, 0), getPosY(2, PI/2, 0));

    endShape(CLOSE);
    // === END BODY ===

    fill(finColor);

    // === START DORSAL FIN ===
    beginShape();
    vertex(j.get(4).x, j.get(4).y);
    bezierVertex(j.get(5).x, j.get(5).y, j.get(6).x, j.get(6).y, j.get(7).x, j.get(7).y);
    bezierVertex(j.get(6).x + cos(a.get(6) + PI/2) * headToMid2 * 16 * scaleFactor, 
                 j.get(6).y + sin(a.get(6) + PI/2) * headToMid2 * 16 * scaleFactor, 
                 j.get(5).x + cos(a.get(5) + PI/2) * headToMid1 * 16 * scaleFactor, 
                 j.get(5).y + sin(a.get(5) + PI/2) * headToMid1 * 16 * scaleFactor, 
                 j.get(4).x, j.get(4).y);
    endShape();
    // === END DORSAL FIN ===

    // === START EYES ===
    fill(255);
    ellipse(getPosX(0, PI/2, -18 * scaleFactor), getPosY(0, PI/2, -18 * scaleFactor), 24 * scaleFactor, 24 * scaleFactor);
    ellipse(getPosX(0, -PI/2, -18 * scaleFactor), getPosY(0, -PI/2, -18 * scaleFactor), 24 * scaleFactor, 24 * scaleFactor);
    // === END EYES ===
  }

  void debugDisplay() {
    spine.display();
  }

  // Various helpers to shorten lines
  float getPosX(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).x + cos(spine.angles.get(i) + angleOffset) * (bodyWidth[i] + lengthOffset * scaleFactor);
  }

  float getPosY(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).y + sin(spine.angles.get(i) + angleOffset) * (bodyWidth[i] + lengthOffset * scaleFactor);
  }
}
